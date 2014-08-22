class ManifestParsingError < RuntimeError
  def self.invalid_value_for_integer(value, target_field)
    ManifestParsingError.new "'#{value}' is not a valid value for '#{target_field}' (must be an integer)"
  end
end
