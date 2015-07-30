module Entity
  extend ActiveSupport::Concern

  included do
    serialize :custom_fields, Hash
    serialize :indexed_fields, Hash

    after_initialize do
      self.custom_fields  ||= {}
      self.indexed_fields ||= {}
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
    self.indexed_fields.deep_merge_not_nil!(entity.indexed_fields)

    self
  end

  def merge_entity_scope(entity, scope)
    if (data = entity.plain_sensitive_data[scope].presence)
      self.plain_sensitive_data[scope] ||= {}
      self.plain_sensitive_data[scope].deep_merge_not_nil!(data)
    end

    if (data = entity.custom_fields[scope].presence)
      self.custom_fields[scope] ||= {}
      self.custom_fields[scope].deep_merge_not_nil!(data)
    end

    if (data = entity.indexed_fields[scope].presence)
      self.indexed_fields[scope] ||= {}
      self.indexed_fields[scope].deep_merge_not_nil!(data)
    end
  end

  def move_entity_scope(scope, entity)
    if (data = self.plain_sensitive_data.delete(scope))
      entity.plain_sensitive_data[scope] ||= {}
      entity.plain_sensitive_data[scope].reverse_deep_merge! data
    end

    if (data = self.custom_fields.delete(scope))
      entity.custom_fields[scope] ||= {}
      entity.custom_fields[scope].reverse_deep_merge! data
    end

    if (data = self.indexed_fields.delete(scope))
      entity.indexed_fields[scope] ||= {}
      entity.indexed_fields[scope].reverse_deep_merge! data
    end
  end

private

  def encrypt_sensitive_data
    self.sensitive_data = MessageEncryption.encrypt Oj.dump(plain_sensitive_data)
    self
  end
end