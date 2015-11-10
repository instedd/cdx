module Entity
  extend ActiveSupport::Concern

  included do
    serialize :custom_fields, Hash
    serialize :core_fields, Hash

    after_initialize do
      self.custom_fields  ||= {}
      self.core_fields ||= {}
    end

    before_save :encrypt_sensitive_data
    before_save :set_phantom_flag

    validate    :valid_core_fields
    validate    :valid_sensitive_fields
  end

  attr_writer :plain_sensitive_data

  def plain_sensitive_data
    @plain_sensitive_data ||= Oj.load(MessageEncryption.decrypt(sensitive_data)) || {}
  end

  def reload
    @plain_sensitive_data = nil
    super
  end

  def merge(entity)
    self.plain_sensitive_data.deep_merge_not_nil!(entity.plain_sensitive_data)
    self.custom_fields.deep_merge_not_nil!(entity.custom_fields)
    self.core_fields.deep_merge_not_nil!(entity.core_fields)

    self
  end

  def empty_entity?
    self.plain_sensitive_data.except('custom').blank? &&
      self.plain_sensitive_data.try(:[], 'custom').blank? &&
      self.core_fields.blank? &&
      self.custom_fields.blank?
  end

  def entity_scope
    self.class.entity_scope
  end

  def core_field_value(field)
    core_fields[field.name]
  end

  def uuids
    Array(self.uuid)
  end

  def phantom?
    self.is_phantom && !has_entity_id?
  end

  def not_phantom?
    not phantom?
  end

  def valid_core_fields
    valid_fields(self.core_fields, self.errors['core_fields'], entity_fields, false)
  end

  def valid_sensitive_fields
    valid_fields(self.plain_sensitive_data, self.errors['plain_sensitive_data'], entity_fields, true)
  end

  def valid_fields(fields, errors, field_definitions, are_sensitive)
    fields.each do |key, value|
      next if are_sensitive && key == 'custom'
      if (entity_field = field_definitions.find{|f| f.name == key}).nil?
        errors << "#{key} is not supported for entity #{self.class.name.humanize}"
      elsif (!!entity_field.pii? != are_sensitive)
        errors << "#{key} is marked as#{entity_field.pii? ? ' ' : ' not '}sensitive"
      elsif (field_error = entity_field.validate(value))
        errors << field_error
      elsif entity_field.nested?
        value.each {|nested_fields| valid_fields(nested_fields, errors, entity_field.sub_fields, are_sensitive) }
      end
    end
  end

  def entity_fields
    self.class.entity_fields
  end

  class_methods do
    def within_time(time_span, relative_to)
      where('created_at > ?', relative_to - time_span)
    end

    def entity_fields
      Cdx.core_field_scopes.find{|s| s.name == entity_scope}.fields
    end
  end

protected

  def set_phantom_flag
    self.is_phantom = phantom? if respond_to?(:'is_phantom=')
    true
  end

  def validate_sample
    if self.sample
      errors.add(:sample, "must belong to the same institution as this #{self.model_name.singular.humanize}") if self.institution_id != sample.institution_id
      errors.add(:sample, "must belong to the same encounter as this #{self.model_name.singular.humanize}") if self.encounter_id != sample.encounter_id
      errors.add(:sample, "must belong to the same patient as this #{self.model_name.singular.humanize}") if self.patient_id != sample.patient_id
    end
  end

  def validate_encounter
    if self.encounter
      errors.add(:encounter, "must belong to the same institution as this #{self.model_name.singular.humanize}") if self.institution_id != encounter.institution_id
      errors.add(:encounter, "must belong to the same patient as this #{self.model_name.singular.humanize}") if self.patient_id != encounter.patient_id
    end
  end

  def validate_patient
    if self.patient
      errors.add(:patient, "must belong to the same institution as this #{self.model_name.singular.humanize}") if self.institution_id != patient.institution_id
    end
  end

private

  def encrypt_sensitive_data
    self.sensitive_data = MessageEncryption.encrypt Oj.dump(plain_sensitive_data)
    self
  end
end
