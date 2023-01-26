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

  scope :partial_name, ->(name) {
    where("name LIKE ?", "%#{sanitize_sql_like(name)}%") unless name.blank?
  }

  scope :partial_sample_uuid, ->(sample_uuid) {
    joins(samples: :sample_identifiers).where("sample_identifiers.uuid LIKE ?", "%#{sanitize_sql_like(sample_uuid)}%") unless sample_uuid.blank?
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


  private

  def there_are_samples
    samples_with_results = samples_report_samples.select { |srs| !srs.sample.measured_signal.nil? }
    errors.add(:base, "Please select a box containing samples with results") if samples_with_results.empty?
  end

end