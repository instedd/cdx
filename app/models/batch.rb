class Batch < ApplicationRecord
  include Entity
  include AutoUUID
  include Resource
  include SpecimenRole
  include InactivationMethod
  include SiteContained
  include DateProduced

  validates_presence_of :institution

  has_many :samples, dependent: :destroy, autosave: true

  def self.entity_scope
    "batch"
  end

  attribute_field :isolate_name, copy: true
  attribute_field :batch_number, copy: true
  attribute_field :date_produced, copy: true
  attribute_field :lab_technician,
                  :specimen_role,
                  :inactivation_method,
                  :volume

  validates_presence_of :inactivation_method
  validates_presence_of :volume
  validates_presence_of :lab_technician
  validates_numericality_of :volume, greater_than: 0, message: "value must be greater than 0"
  validates_presence_of :batch_number
  validates_presence_of :isolate_name
  validates_uniqueness_of :batch_number, scope: :isolate_name, message: "and Isolate Name combination should be unique"

  validates_associated :samples, message: "are invalid"

  def qc_sample
    self.samples.select {|sample| sample.is_quality_control?}.first
  end

  def has_qc_sample?
    self.qc_sample.present?
  end

end
