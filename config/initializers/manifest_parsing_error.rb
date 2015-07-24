class ManifestParsingError < RuntimeError
  attr_reader :target_field
  attr_accessor :record_index

  def initialize(message, target_field = nil)
    super(message)
    @target_field = target_field
  end

  def self.invalid_value_for_integer(value, target_field)
    new "'#{value}' is not a valid value for '#{target_field}' (must be an integer)", target_field
  end

  def self.invalid_mapping(value, target_field, mappings)
    new "'#{value}' is not a valid value for '#{target_field}' (valid value must be in one of these forms: #{mappings.map(){|f| f["when"]}.join(", ")})", target_field
  end

  def self.null_not_allowed(target_field)
    new "String 'null' is not permitted as value, in field '#{target_field}'", target_field
  end

  def self.invalid_value_for_options(value, target_field, options)
    new "'#{value}' is not a valid value for '#{target_field}' (valid options are: #{options.join(', ')})", target_field
  end

  def self.invalid_value_for_range(value, target_field, min, max)
    new "'#{value}' is not a valid value for '#{target_field}' (valid values must be between #{min} and #{max})", target_field
  end

  def self.invalid_value_for_date(value, target_field)
    new "'#{value}' is not a valid value for '#{target_field}' (valid value must be an iso date)", target_field
  end

  def self.unsupported_date_format
    new "Date format not implemented"
  end

  def self.unsupported_time_unit(time_unit, target_field)
    new "'#{time_unit} is not a valid time unit for #{target_field}.", target_field
  end

  def self.empty_message
    new "Empty message reported"
  end

  def self.invalid_manifest(manifest)
    new "Cannot apply invalid manifest to document:\n #{manifest.errors.full_messages.join("\n ")}"
  end

  def self.custom_field_not_defined(target_field)
    new "Custom field #{target_field} must be defined in manifest."
  end

  def self.script_error(target_field, message)
    new "Error executing script while mapping the field '#{target_field}': #{message}"
  end

  def self.invalid_script(target_field)
    new "JSONObject is not a valid return type for '#{target_field}' script"
  end

  def self.no_manifest(device_model)
    new "There is no manifest for model: #{device_model.name}."
  end
end
