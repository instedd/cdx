class ManifestField
  attr_reader :target_field
  subclass_responsibility :hash_key, :custom?, :core?, :indexed?

  def self.for(manifest, target_field, field_mapping, device=nil)
    if core_field = core_field_from(target_field)
      CoreManifestField.for(manifest, target_field, field_mapping, device, core_field)
    else
      CustomManifestField.for(manifest, target_field, field_mapping, device, custom_field_from(manifest))
    end
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

  def source
    @field_mapping
  end

  private

  def scope_from_target
    @target_field.split(Manifest::PATH_SPLIT_TOKEN).first
  end

  def target_without_scope
    index = @target_field.index(Manifest::PATH_SPLIT_TOKEN)
    @target_field[index + 1 .. -1]
  end

  private

  def self.core_field_from(target_field)
    target_path = target_field
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

  def self.custom_field_from(manifest)
    manifest.custom_fields.detect{|x| x['name'] == target_field}
  end
end
