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

  attribute_field :name, copy: true
  attribute_field :threshold, copy: true

end