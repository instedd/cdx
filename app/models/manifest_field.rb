class ManifestField
  attr_reader :target_field
  subclass_responsibility :store_target, :custom?

  def self.for(manifest, target_field, field_mapping)
    if core_field = core_field_from(target_field)
      CoreManifestField.for(manifest, target_field, field_mapping, core_field)
    else
      CustomManifestField.for(manifest, target_field, field_mapping, custom_field_from(manifest, target_field), custom_field_scope(target_field))
    end
  end

  def apply_to(data, message, device)
    value = ManifestFieldMapping.new(@manifest, self, device, data).apply
    @validation.apply_to value
    store value, message
  end

  def store value, message
    if value.present?
      index value, target_without_scope, message.get_in(*store_target)
    end
    message
  end

  def index value, target, message
    paths = target.split Manifest::PATH_SPLIT_TOKEN

    if scope.is_a?(Cdx::Field::NestedField)
      # Assume it's "nested.field"
      array = message[paths[0]] ||= []
      Array(value).each_with_index do |sub_value, index|
        array[index] ||= {}
        array[index][paths[1]] = sub_value
      end
    else
      message = paths[0...-1].inject message do |current, path|
        current[path] ||= {}
      end
      message[paths.last] ||= value
    end
  end

  def source
    @field_mapping
  end

  protected

  def scope_from_target
    @target_field.split(Manifest::PATH_SPLIT_TOKEN).first
  end

  def target_without_scope
    index = @target_field.index(Manifest::PATH_SPLIT_TOKEN)
    @target_field[index + 1 .. -1]
  end

  private

  def self.core_field_from(target_field)
    target_path = target_field.split(Manifest::PATH_SPLIT_TOKEN)
    cdx_scope, cdx_field = scope_and_field(target_path)

    target_path.each do |path|
      return nil unless cdx_field.present?
      cdx_field = cdx_field.sub_fields.detect{|x| x.name == path}
    end

    cdx_field
  end

  def self.custom_field_from(manifest, target_field)
    manifest.custom_fields[target_field]
  end

  def self.custom_field_scope(target_field)
    target_path = target_field.split(Manifest::PATH_SPLIT_TOKEN)
    target_path.pop

    cdx_scope, cdx_field = scope_and_field(target_path)

    cdx_field.is_a?(Cdx::Field::NestedField) ? cdx_field : nil
  end

  def self.scope_and_field(target_path)
    scope = target_path.shift
    field = target_path.shift
    cdx_scope = Cdx::Fields.entities.core_field_scopes.detect{|x| x.name == scope}
    cdx_field = cdx_scope.fields.detect{|x| x.name == field}
    [cdx_scope, cdx_field]
  end
end
