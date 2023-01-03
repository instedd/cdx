module Entity
  extend ActiveSupport::Concern

  included do
    # serialize :custom_fields, JSON
    # serialize :core_fields, JSON

    after_initialize do
      self.custom_fields  ||= {}
      self.core_fields ||= {}
    end

    before_save :encrypt_sensitive_data
    before_save :set_phantom_flag

    validate    :valid_core_fields
    validate    :valid_sensitive_fields

    acts_as_paranoid

    # Creates accessors for Entity fields
    #
    # `attribute_field :foo, :bar` will generate r/w accessors for foo and bar fields, despite pii value
    # `attribute_field :foo, source: :foo_field_name` will use "foo_field_name" as the source.
    # `attribute_field :foo, copy: true` will ensure a copy of the value is keept in the foo attribute
    #
    def self.attribute_field(*args)
      options = args.extract_options!
      options.reverse_merge! copy: false
      do_copy = options[:copy]

      args.each do |arg|
        field_name = (options[:field] || arg).to_s
        field_source = if self.entity_fields.detect { |f| f.name == field_name }.pii?
          "plain_sensitive_data"
        else
          "core_fields"
        end

        define_method arg do
          send(field_source)[field_name]
        end

        define_method "#{arg}=" do |value|
          write_attribute(arg, value) if do_copy
          if value.blank?
            send(field_source).delete(field_name)
          else
            send(field_source)[field_name] = value
          end
        end

        if do_copy
          # copy attribute to db, in case the entity_field was changed directly
          before_validation do
            write_attribute(arg, send(arg))
          end
        end
      end
    end
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

  def pii_data
    pii = {entity_scope => plain_sensitive_data}
    pii = pii.deep_merge(sample.entity_scope => sample.plain_sensitive_data) if respond_to?(:sample) && sample
    pii = pii.deep_merge(encounter.entity_scope => encounter.plain_sensitive_data) if respond_to?(:encounter) && encounter
    pii = pii.deep_merge(patient.entity_scope => patient.plain_sensitive_data) if respond_to?(:patient) && patient
    pii
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
      key = key.to_s
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
      where("#{table_name}.created_at > ?", relative_to - time_span)
    end

    def entity_fields
      @entity_fields ||= Cdx::Fields.entities.core_field_scopes.find{|s| s.name == entity_scope}.fields
    end

    def existing_entity(name)
      where("JSON_CONTAINS_PATH(#{quoted_table_name}.core_fields, 'one', #{entity_field_name_as_json_path(name)})")
    end

    def missing_entity(name)
      where("NOT JSON_CONTAINS_PATH(#{quoted_table_name}.core_fields, 'one', #{entity_field_name_as_json_path(name)})")
    end

    def where_entity(name, value)
      where("#{quoted_table_name}.core_fields->>#{entity_field_name_as_json_path(name)} = ?", value)
    end

    def where_entity_not(name, value)
      where("#{quoted_table_name}.core_fields)->>#{entity_field_name_as_json_path(name)} <> ?", value)
    end

    def entity_field_name_as_json_path(field_name)
      field_name = field_name.to_s

      if Rails.env.production? || entity_fields.any? { |f| f.name == field_name }
        connection.quote("$.#{field_name}")
      else
        raise ArgumentError.new("BUG: unknown entity field #{field_name} for #{self.class.name}")
      end
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
