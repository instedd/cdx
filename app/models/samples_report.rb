class SamplesReport < ApplicationRecord
  include Entity
  include Resource
  include SiteContained

  validates_presence_of :institution

  has_many :samples_report_samples, dependent: :destroy
  has_many :samples, through: :samples_report_samples

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
    joins("LEFT JOIN samples_report_samples ON samples_report_samples.samples_report_id = samples_reports.id
      LEFT JOIN samples ON samples_report_samples.sample_id = samples.id
      LEFT JOIN boxes ON boxes.id = samples.box_id")
      .where("boxes.uuid LIKE ?", "%#{sanitize_sql_like(box_uuid)}%")
      .group(:samples_report_id) unless box_uuid.blank?
  }

  scope :partial_batch_number, ->(batch_number) {
    joins("LEFT JOIN samples_report_samples ON samples_report_samples.samples_report_id = samples_reports.id
      LEFT JOIN samples ON samples_report_samples.sample_id = samples.id
      LEFT JOIN batches ON batches.id = samples.batch_id")
      .where("batches.batch_number LIKE ?", "%#{sanitize_sql_like(batch_number)}%")
      .group(:samples_report_id) unless batch_number.blank?
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

  def target_batch
    # The target batch for this box is the batch of any sample which distractor is false or null
    samples_report_samples.joins(:sample).where("samples.distractor IS NULL OR samples.distractor = false").first.sample.batch
  end

  private

  def there_are_samples
    samples_with_measurements = samples_report_samples.select { |srs| !srs.sample.measured_signal.nil? }
    errors.add(:base, "The selected box should contain samples with uploaded measurements") if samples_with_measurements.empty?
  end
end
