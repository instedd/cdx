class ManifestField
  attr_reader :target_field

  def initialize(manifest, field, scope=nil)
    @manifest = manifest
    @field = field
    @target_field = @field["target_field"]
    @validation = ManifestFieldValidation.new(@field)
    @scope = scope
  end

  def apply_to(data, message, device)
    value = ManifestFieldMapping.new(@manifest, @field, device, data).apply
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
    return "pii" if @field["pii"]
    if @field["core"]
      "indexed"
    else
      return "indexed" if @field["indexed"]
      "custom"
    end
  end


  def index value, target, message, custom=false
    if (targets = target.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1

      message, custom = index [], targets.first, message, custom

      Array(value).each_with_index do |element, index|
        index(element, targets.drop(1).join(Manifest::COLLECTION_SPLIT_TOKEN), (message[index]||={}), custom)
      end
    else
      paths = target.split Manifest::PATH_SPLIT_TOKEN
      message = paths[0...-1].inject message do |current, path|
        current[path] ||= {}
      end
      if @field["indexed"] && !@field["core"] && target != "results" && !custom
        message = message["custom_fields"] ||= {}
        custom = true
      end
      [(message[paths.last] ||= value), custom]
    end
  end
end
