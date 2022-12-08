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

  private

  def there_are_samples
    errors.add(:base, "Please select a box containing samples with results") if samples_report_samples.empty?
  end

end