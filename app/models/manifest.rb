class Manifest < ActiveRecord::Base
  has_and_belongs_to_many :device_models

  validate :manifest_validation
  before_save :update_models
  before_save :update_version
  before_save :update_api_version

  def self.default
    new definition: default_definition
  end

  def update_models
    self.device_models = Array(metadata["device_models"] || []).map { |model| DeviceModel.find_or_create_by(name: model)}
  end

  def update_version
    self.version = metadata["version"]
  end

  def update_api_version
    self.api_version = metadata["api_version"]
  end

  def metadata
    Oj.load(self.definition)["metadata"] rescue {}
  end

  def apply_to(data)
    decoded = Oj.load(definition)
    decoded["field_mapping"].inject(indexed: Hash.new, pii: Hash.new, custom: Hash.new) do |event, mapping|
      apply_single_mapping(mapping, data, event)
    end
  end

  def apply_single_mapping(mapping, data, event)
    target_field = mapping["target_field"]
    selector = mapping["selector"]
    value = apply_selector(selector, data)
    check_valid_value(value, mapping, target_field, mapping["valid_values"])
    value = apply_value_mappings(value, target_field, mapping["value_mappings"])
    key = hash_key(target_field, mapping["core"], mapping["indexed"], mapping["pii"])

    if (targets = target_field.split("[*].")).size > 1
      # find the array or create it. Only one level for now
      target_array = event[key][targets.first] ||= Array.new
      # merge the new values
      value.each_with_index do |value, index|
        (target_array[index] ||= Hash.new)[targets[-1]] = value
      end
    else
      event[key][target_field] = value
    end

    event
  end

  def apply_selector(selector, data)
    if (targets = selector.split("[*].")).size > 1

      paths = targets.first.split "."

      elements_array = paths.inject data do |current, path|
        current[path] || []
      end
      elements_array.map do |element|
        paths = targets.last.split "."
        paths.inject element do |current, path|
          current[path]
        end
      end
    else
      paths = selector.split "."
      paths.inject data do |current, path|
        current[path]
      end
    end
  end

  def hash_key(target_field, core, indexed, pii)
    if core
      return :pii if Event.pii?(target_field)
      :indexed
    else
      return :pii if pii
      return :indexed if indexed
      :custom
    end
  end

  def check_valid_value(value, mapping, target_field, valid_values)
    if mapping['type'] == 'integer' and value.present? and !value.is_a? Integer
      if value.to_i.to_s != value
        raise ManifestParsingError.new "'#{value}' is not a valid value for '#{target_field}' (must be an integer)"
      end
    end

    return value if valid_values ==  nil

    if value.is_a? Array
      value.each do |v|
        check_valid_value v, target_field, valid_values
      end
    end

    if options = valid_values["options"]
      check_value_in_options(value, target_field, options)
    end

    if range = valid_values["range"]
      check_value_in_range(value, target_field, range)
    end

    if date = valid_values["date"]
      check_value_is_date(value, target_field, date)
    end
  end

  def check_value_in_options(value, target_field, options)
    unless options.include? value
      raise ManifestParsingError.new "'#{value}' is not a valid value for '#{target_field}' (valid options are: #{options.join ", "})"
    end
  end

  def check_value_in_range(value, target_field, range)
    min = range["min"]
    max = range["max"]

    unless min <= value and value <= max
      raise ManifestParsingError.new "'#{value}' is not a valid value for '#{target_field}' (valid values must be between #{min} and #{max})"
    end
  end

  def check_value_is_date(value, target_field, date_format)
    case date_format
    when "iso"
      Time.parse(value) rescue raise ManifestParsingError.new "'#{value}' is not a valid value for '#{target_field}' (valid value must be an iso date)"
    else
      raise ManifestParsingError.new "Date format not implemented"
    end
  end

  def apply_value_mappings(value, target_field, mappings)
    return value unless mappings

    matched_mapping = mappings.keys.detect do |mapping|
      value.match mapping.gsub("*", ".*")
    end

    if matched_mapping
      mappings[matched_mapping]
    else
      raise ManifestParsingError.new "'#{value}' is not a valid value for '#{target_field}' (valid value must be in one of these forms: #{mappings.keys.join ", "})"
    end
  end

  def self.default_definition
    field_mapping = Event.sensitive_fields.map do |sensitive_field|
      {
        target_field: sensitive_field,
        selector: sensitive_field,
        core: true,
        type: 'string',
        pii: true,
        indexed: false
      }
    end

    field_mapping.concat(map(Cdx::Api.searchable_fields).flatten)
    Oj.dump field_mapping: field_mapping
  end

  private

  def self.map fields, selector_prefix=""
    fields.map do |field_definition|
      field = selector_prefix + field_definition[:name]
      if field_definition[:type] == "nested"
        map field_definition[:sub_fields], "#{selector_prefix}#{field_definition[:name]}[*]."
      else
        {
          target_field: field,
          selector: field,
          type: field_definition[:type],
          core: true,
          pii: false,
          indexed: true
        }
      end
    end
  end

  def manifest_validation
    if self.metadata.blank?
      self.errors.add(:metadata, "can't be blank")
    else
      fields =  ["version","api_version","device_models"]
      check_fields_in_metadata(fields)
    end

    check_field_mapping

  rescue Oj::ParseError => ex
    self.errors.add(:parse_error, ex.message)
  end

  def check_fields_in_metadata(fields)
    m = self.metadata
    fields.each do |f|
      if m[f].blank?
        self.errors.add(:metadata, "must include "+ f +" field")
      end
    end
  end

  def check_field_mapping
    definition = Oj.load self.definition
    if definition["field_mapping"].is_a? Array
      definition["field_mapping"].each do |fm|
        if (fm["core"] == true)
          check_valid_values fm
          check_value_mappings fm
        end
      end
    else
      self.errors.add(:field_mapping, "must be an array")
    end
  end

  def check_valid_values(field_mapping)
    if (! field_mapping["valid_values"].blank?)
      self.errors.add(:invalid_field_mapping, ": target '#{field_mapping["target_field"]}'. Valid values are not permitted for core fields")
    end
  end

  def check_value_mappings(field_mapping)
    searchable_fields = Cdx::Api.searchable_fields
    if(! field_mapping["value_mappings"].blank?)
      target = searchable_fields.select { |f| f.name == field_mapping["target_field"] }.first
      field_mapping["value_mappings"].values.each do |vm|
        #Assuming there is an options key for valid_values field
        if !target["valid_values"]["options"].include? vm
          self.errors.add(:invalid_field_mapping, ": target '#{field_mapping["target_field"]}'. '#{vm}' is not a valid value")
        end
      end
    end
  end

end
