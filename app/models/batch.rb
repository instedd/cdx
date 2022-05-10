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

  validate :isolate_name_batch_number_combination_create, on: :create
  validate :isolate_name_batch_number_combination_update, on: :update

  validates_associated :samples, message: "are invalid"

  def qc_sample
    self.samples.select {|sample| sample.is_quality_control?}.first
  end

  def has_qc_sample?
    self.qc_sample.present?
  end

  def qc_info
    if qc_sample = self.qc_sample
      QcInfo.find_or_duplicate_from(qc_sample)
    end
  end

  def build_sample(**attributes)
    samples.build(
      institution_id: institution_id,
      site_id: site_id,
      sample_identifiers: [SampleIdentifier.new],
      isolate_name: isolate_name,
      inactivation_method: inactivation_method,
      **attributes
    )
  end

  private

  def isolate_name_batch_number_combination_create
    validate_isolate_name_batch_number_combination {
      [ "#{query} AND id IS NOT NULL" ] + query_params
    }
  end

  def isolate_name_batch_number_combination_update
    validate_isolate_name_batch_number_combination {
      [ "#{query} AND id != ?" ] + query_params + [ id ]
    }
  end

  def query
    "LOWER(isolate_name) = ? AND LOWER(batch_number) = ?"
  end

  def query_params
    [ isolate_name.downcase, batch_number.downcase ]
  end

  def validate_isolate_name_batch_number_combination
    return unless (present?(:isolate_name) && present?(:batch_number))

    combination_exists = Batch.where(yield).exists?
    if combination_exists
      errors.add(:isolate_name, "and Batch Number combination should be unique")
    end
  end

  def present?(attr_name)
    valid = self[attr_name].present?
    errors.add(attr_name, "can't be blank") unless valid
    valid
  end
end
