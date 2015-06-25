class CoreManifestField < ManifestField
  attr_reader :target_field, :core_field
  delegate :options, :valid_values, :pii?, :type, to: :core_field

  def self.for(manifest, target_field, field_mapping, device, core_field)
    raise ManifestParsingError.custom_field_not_defined(target_field) unless core_field

    new manifest, target_field, field_mapping, device, core_field
  end

  def initialize(manifest, target_field, field_mapping, device, core_field)
    @manifest = manifest
    @target_field = target_field
    @field_mapping = field_mapping
    @device = device
    @core_field = core_field
    @validation = ManifestFieldValidation.new(self)
  end

  def hash_key
    if pii?
      'pii'
    else
      'indexed'
    end
  end

  def custom?
    false
  end

  def core?
    true
  end

  def indexed?
    !pii?
  end
end
