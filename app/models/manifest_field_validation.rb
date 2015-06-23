class ManifestFieldValidation
  def initialize(field)
    @field = field
    @valid_values = @field["valid_values"]
    @target_field = @field["target_field"]
  end

  def apply_to(value)
    return unless value.present?

    if @field['type'] == 'integer' && !self.class.is_an_integer?(value)
      raise ManifestParsingError.invalid_value_for_integer(value, @target_field)
    end

    verify_value_is_not_null_string value

    if value.is_a? Array
      value.each do |v|
        apply_to v
      end
    else
      check_value_in_options(value, @field["options"]) if @field["options"] && @field["type"] == "enum"
      check_value_in_range(value, @valid_values["range"]) if @valid_values && @valid_values["range"]
      check_value_is_date(value, @valid_values["date"]) if @valid_values && @valid_values["date"]
    end
  end

  def self.is_an_integer? value
    if value.is_a?(Array)
      !value.empty? && value.all? do |element|
        is_an_integer? element
      end
    else
      value.is_a?(Integer) || value.to_i.to_s == value
    end
  end

  def verify_value_is_not_null_string value
    unless value != Manifest::NULL_STRING
      raise ManifestParsingError.null_not_allowed(@target_field)
    end
  end

  def check_value_in_options(value, options)
    unless options.include? value
      raise ManifestParsingError.invalid_value_for_options(value, @target_field, options)
    end
  end

  def check_value_in_range(value, range)
    unless range["min"] <= value and value <= range["max"]
      raise ManifestParsingError.invalid_value_for_range(value, @target_field, range["min"], range["max"])
    end
  end

  def check_value_is_date(value, date_format)
    case date_format
    when "iso"
      Time.parse(value) rescue raise ManifestParsingError.invalid_value_for_date(value, @target_field)
    else
      raise ManifestParsingError.unsupported_date_format
    end
  end
end
