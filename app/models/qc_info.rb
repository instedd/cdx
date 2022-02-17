class QcInfo < ActiveRecord::Base
  include Entity
  include SpecimenRole
  include InactivationMethod
  include DateProduced

  has_many :assay_attachments, dependent: :destroy
  accepts_nested_attributes_for :assay_attachments, allow_destroy: true
  validates_associated :assay_attachments, message: "are invalid"

  has_many :notes, dependent: :destroy
  accepts_nested_attributes_for :notes, allow_destroy: true
  validates_associated :notes, message: "are invalid"

  def self.entity_scope
    "qcInfo"
  end

  attribute_field :uuid, copy: true
  attribute_field :batch_number, copy: true
  attribute_field :date_produced,
                  :lab_technician,
                  :inactivation_method,
                  :volume,
                  :isolate_name,
                  :specimen_role

end

