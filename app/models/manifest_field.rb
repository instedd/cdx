class ManifestField
  def initialize(manifest, field, scope=nil, device=nil)
    @manifest = manifest
    @field = field
    @target_field = @field["target_field"]
    @mapping = ManifestFieldMapping.new(@manifest, @field, device)
    @validation = ManifestFieldValidation.new(@field)
    @scope = scope
    @device = device
  end

  def apply_to(data, event)
    value = @mapping.apply_to data
    @validation.apply_to value
    store value, event
  end

  def store value, event
    if value.present?
      index value, @target_field, event[@scope][hash_key]
    end
    event
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


  def index value, target, event, custom=false
    if (targets = target.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1

      event, custom = index [], targets.first, event, custom

      Array(value).each_with_index do |element, index|
        index(element, targets.drop(1).join(Manifest::COLLECTION_SPLIT_TOKEN), (event[index]||={}), custom)
      end
    else
      paths = target.split Manifest::PATH_SPLIT_TOKEN
      event = paths[0...-1].inject event do |current, path|
        current[path] ||= {}
      end
      if @field["indexed"] && !@field["core"] && target != "results" && !custom
        event = event["custom_fields"] ||= {}
        custom = true
      end
      [(event[paths.last] ||= value), custom]
    end
  end
end
