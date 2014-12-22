class ManifestField
  def initialize(manifest, field)
    @manifest = manifest
    @field = field
    @target_field = @field["target_field"]
    @mapping = ManifestFieldMapping.new(@manifest, @field)
    @validation = ManifestFieldValidation.new(@field)
  end

  def apply_to(data, event)
    value = @mapping.apply_to data
    @validation.apply_to value
    store value, event
  end

  def store value, event
    if (targets = @target_field.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1
      # find the array or create it. Only one level for now
      target_array = event[hash_key][targets.first] ||= Array.new
      # merge the new values
      if value.present?
        Array(value).each_with_index do |value, index|
          (target_array[index] ||= Hash.new)[targets[-1]] = value
        end
      end
    else
      event[hash_key][@target_field] = value
    end

    event
  end

  def hash_key
    if @field["core"]
      return :pii if Event.pii?(@target_field)
      :indexed
    else
      return :pii if @field["pii"]
      return :indexed if @field["indexed"]
      :custom
    end
  end
end
