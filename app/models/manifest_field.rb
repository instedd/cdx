class ManifestField
  attr_reader :target_field

  def initialize(manifest, target_field, field_mapping, device=nil)
    @manifest = manifest
    @target_field = target_field
    @field_mapping = field_mapping
    @validation = ManifestFieldValidation.new(self)
    @device = device
  end

  def apply_to(data, message)
    value = ManifestFieldMapping.new(@manifest, self, @device, data).apply
    @validation.apply_to value
    store value, message
  end

  def store value, message
    if value.present?
      index value, target_without_scope, message[scope_from_target][hash_key]
    end
    message
  end

  def hash_key
    if pii?
      'pii'
    elsif core?
      'indexed'
    else
      'custom'
    end
  end

  def index value, target, message
    if (targets = target.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1

      message = index [], targets.first, message

      Array(value).each_with_index do |element, index|
        index(element, targets.drop(1).join(Manifest::COLLECTION_SPLIT_TOKEN), (message[index]||={}))
      end
    else
      paths = target.split Manifest::PATH_SPLIT_TOKEN
      message = paths[0...-1].inject message do |current, path|
        current[path] ||= {}
      end
      message[paths.last] ||= value
    end
  end

  def valid_values
    if custom?
      custom_field['valid_values']
    else
      core_field.valid_values
    end
  end

  def type
    if custom?
      custom_field['type']
    else
      core_field.type
    end
  end

  def options
    if custom?
      custom_field['options']
    else
      core_field.options
    end
  end

  def source
    @field_mapping
  end

  def custom?
    custom_field.present?
  end

  def core?
    !custom?
  end

  def indexed?
    if custom?
      custom_field['indexed'] || false
    else
      true
    end
  end

  def pii?
    if custom?
      custom_field["pii"] || false
    else
      core_field.pii?
    end
  end

  private

  def scope_from_target
    @target_field.split(Manifest::PATH_SPLIT_TOKEN).first
  end

  def target_without_scope
    index = @target_field.index(Manifest::PATH_SPLIT_TOKEN)
    @target_field[index + 1 .. -1]
  end

  def custom_field
    @custom_field ||= @manifest.custom_fields.detect{|x| x.name = @target_field}
  end

  def core_field
    @core_field ||= begin
      target_path = @target_field
        .gsub(Manifest::COLLECTION_SPLIT_TOKEN, Manifest::PATH_SPLIT_TOKEN)
        .split(Manifest::PATH_SPLIT_TOKEN)

      scope = target_path.shift
      field = target_path.shift
      cdx_scope = Cdx.core_field_scopes.detect{|x| x.name == scope}
      cdx_field = cdx_scope.fields.detect{|x| x.name == field}

      target_path.each do |path|
        cdx_field = cdx_field.sub_fields.detect{|x| x.name == path}
      end

      cdx_field
    end
  end
end
