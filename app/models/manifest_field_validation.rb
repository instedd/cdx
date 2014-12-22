class ManifestFieldValidation
  def initialize(field)
    @field = field
    @valid_values = @field["valid_values"]
    @target_field = @field["target_field"]
  end

  def apply_to(value)
    return unless value.present?

    if @field['type'] == 'integer' && !value.is_a?(Integer) && value.to_i.to_s != value
      raise ManifestParsingError.invalid_value_for_integer value, @target_field
    end

    verify_value_is_not_null_string value

    return value unless @valid_values

    if value.is_a? Array
      value.each do |v|
        apply_to v
      end
    else
      check_value_in_options(value, @field["options"]) if @field["options"] && @field["type"] == "enum"
      check_value_in_range(value, @valid_values["range"]) if @valid_values["range"]
      check_value_is_date(value, @valid_values["date"]) if @valid_values["date"]
    end
  end

  def verify_value_is_not_null_string value
    if value == Manifest::NULL_STRING
      raise ManifestParsingError.new "String 'null' is not permitted as value, in field '#{@target_field}'"
    end
  end

  def check_value_in_options(value, options)
    unless options.include? value
      raise ManifestParsingError.new "'#{value}' is not a valid value for '#{@target_field}' (valid options are: #{options.join ', '})"
    end
  end

  def check_value_in_range(value, range)
    min = range["min"]
    max = range["max"]

    unless min <= value and value <= max
      raise ManifestParsingError.new "'#{value}' is not a valid value for '#{@target_field}' (valid values must be between #{min} and #{max})"
    end
  end

  def check_value_is_date(value, date_format)
    case date_format
    when "iso"
      Time.parse(value) rescue raise ManifestParsingError.new "'#{value}' is not a valid value for '#{@target_field}' (valid value must be an iso date)"
    else
      raise ManifestParsingError.new "Date format not implemented"
    end
  end
end
