class CustomManifestField < ManifestField
  attr_reader :target_field, :custom_field

  def self.for(manifest, target_field, field_mapping, custom_field, scope)
    raise ManifestParsingError.custom_field_not_defined(target_field) unless custom_field

    new manifest, target_field, field_mapping, custom_field, scope
  end

  def initialize(manifest, target_field, field_mapping, custom_field, scope)
    @manifest = manifest
    @target_field = target_field
    @field_mapping = field_mapping
    @custom_field = custom_field
    @scope = scope
    @validation = ManifestFieldValidation.new(self)
  end

  def hash_key
    pii? ? 'pii' : 'custom'
  end

  def valid_values
    custom_field['valid_values']
  end

  def type
    custom_field['type']
  end

  def options
    custom_field['options']
  end

  def custom?
    true
  end

  def pii?
    custom_field['pii'] || false
  end

  def scope
    @scope
  end
end
