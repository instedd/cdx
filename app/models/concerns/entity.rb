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
  end

  attr_writer :plain_sensitive_data

  def plain_sensitive_data
    @plain_sensitive_data ||= Oj.load(MessageEncryption.decrypt(sensitive_data)) || {}
  end

  def merge(entity)
    self.plain_sensitive_data.deep_merge_not_nil!(entity.plain_sensitive_data)
    self.custom_fields.deep_merge_not_nil!(entity.custom_fields)
    self.core_fields.deep_merge_not_nil!(entity.core_fields)

    self
  end

  def empty_entity?
    self.plain_sensitive_data.blank? &&
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

  class_methods do
    def from_the_past_year(relative_to)
      where('created_at > ?', relative_to - 1.year)
    end
  end

private

  def encrypt_sensitive_data
    self.sensitive_data = MessageEncryption.encrypt Oj.dump(plain_sensitive_data)
    self
  end
end
