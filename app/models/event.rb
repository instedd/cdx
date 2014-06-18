class Event < ActiveRecord::Base
  belongs_to :device
  belongs_to :institution

  def self.pii?(field)
    sensitive_fields.include? field.to_sym
  end

  def self.sensitive_fields
    [
      :patient_id,
      :patient_name,
      :patient_telephone_number,
      :patient_zip_code,
    ]
  end
end
