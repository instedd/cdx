class SamplesReport < ApplicationRecord
  include Entity
  include Resource
  include SiteContained

  validates_presence_of :institution

  has_many :samples_report_samples, dependent: :destroy
  has_many :samples, through: :samples_report_samples
  has_many :boxes, through: :samples

  def self.entity_scope
    "samples_report"
  end

  validate :there_are_samples
  validates_presence_of :name

  attribute_field :name, copy: true
  attribute_field :threshold, copy: true
  attribute_field :lod
  attribute_field :lob

  scope :partial_name, ->(name) {
    where("name LIKE ?", "%#{sanitize_sql_like(name)}%") unless name.blank?
  }

  scope :partial_sample_uuid, ->(sample_uuid) {
    joins(samples: :sample_identifiers)
      .where("sample_identifiers.uuid LIKE ?", "%#{sanitize_sql_like(sample_uuid)}%") unless sample_uuid.blank?
  }

  scope :partial_box_uuid, ->(box_uuid) {
    unless box_uuid.blank?
      where(id: SamplesReportSample
        .select(:samples_report_id)
        .joins(:sample => :box)
        .where("boxes.uuid LIKE ?", "%#{sanitize_sql_like(box_uuid)}%"))
    end
  }

  scope :partial_batch_number, ->(batch_number) {
    # after box transfer, the sample <-> batch relationship will be severed,
    # hence the coalesce to match the old batch number (valid after transfer)
    # then the original batch number (valid before transfer)
    unless batch_number.blank?
      where(id: SamplesReportSample
        .select(:samples_report_id)
        .left_joins(:sample => :batch)
        .where("COALESCE(samples.old_batch_number, batches.batch_number) LIKE ?", "%#{sanitize_sql_like(batch_number)}%"))
    end
  }

  def calculate_lod_and_lob
    concentrations = samples.map(&:concentration)
    signals = Numo::DFloat[*samples.select { |sample| sample.measured_signal.present? }.map(&:measured_signal)]
    concentrations_matrix = Numo::DFloat[*concentrations.map { |c| [c] }]
    lr = Rumale::LinearModel::LinearRegression.new(fit_bias: true)
    lr.fit(concentrations_matrix, signals)

    lod = lr.bias_term
    blank_samples = signals[Numo::DFloat.cast(concentrations).eq(0)]
    if blank_samples.size > 0
      blank_samples_mean = blank_samples.mean
      blank_samples_sd = blank_samples.stddev
      lod = [lod, 3 * blank_samples_sd].max
      lob = blank_samples_mean + 1.645 * blank_samples_sd
    else
      lob = nil
    end

    self.lod = lod.try(:round, 3)
    self.lob = lob.try(:round, 3)
    self.save
  end

  # Returns any sample that isn't a distractor.
  def target_sample
    samples.where.not(distractor: true).take!
  end

  private

  def there_are_samples
    samples_with_measurements = samples_report_samples.select { |srs| !srs.sample.measured_signal.nil? }
    errors.add(:base, "The selected box should contain samples with uploaded measurements") if samples_with_measurements.empty?
  end
end
