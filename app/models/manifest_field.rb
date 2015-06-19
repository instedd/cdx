class ManifestField
  def initialize(manifest, field, scope=nil, device=nil)
    @manifest = manifest
    @field = field
    @target_field = @field["target_field"]
    @validation = ManifestFieldValidation.new(@field)
    @scope = scope
    @device = device
  end

  def apply_to(data, message)
    value = ManifestFieldMapping.new(@manifest, @field, @device, data).apply
    @validation.apply_to value
    store value, message
  end

  def store value, message
    if value.present?
      index value, @target_field, message[@scope][hash_key]
    end
    message
  end

  def hash_key
    case
    when @field['pii']
      'pii'
    when @field['core']
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
end
