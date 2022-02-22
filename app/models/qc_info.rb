class QcInfo < ActiveRecord::Base
  include Entity
  include SpecimenRole
  include InactivationMethod
  include DateProduced

  has_many :samples

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

