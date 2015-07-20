class Manifest < ActiveRecord::Base
  has_and_belongs_to_many :device_models

  validate :manifest_validation

  before_save :update_models
  before_save :update_version
  before_save :update_api_version

  COLLECTION_SPLIT_TOKEN = "[*]."
  PATH_SPLIT_TOKEN = "."

  NULL_STRING = "null"

  CURRENT_VERSION = "1.2.0"

  scope :valid, -> { where(api_version: CURRENT_VERSION) }

  MESSAGE_TEMPLATE = {
    "test" => {"indexed" => Hash.new, "pii" => Hash.new, "custom" => Hash.new},
    "sample" => {"indexed" => Hash.new, "pii" => Hash.new, "custom" => Hash.new},
    "device" => {"indexed" => Hash.new, "pii" => Hash.new, "custom" => Hash.new},
    "patient" => {"indexed" => Hash.new, "pii"=> Hash.new, "custom" => Hash.new}
  }.freeze

  def reload
    @loaded_definition = nil
    super
  end

  def current_models
    self.device_models.to_a.select {|model| model.current_manifest.id == id}
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

  def loaded_definition
    @loaded_definition ||= Oj.load(self.definition)
  end

  def metadata
    loaded_definition["metadata"] || {}
  end

  def field_mapping
    loaded_definition.with_indifferent_access["field_mapping"]
  end

  def custom_fields
    (loaded_definition['custom_fields'] || []).map(&:with_indifferent_access)
  end

  def apply_to(data, device)
    raise ManifestParsingError.empty_message if data.blank?
    raise ManifestParsingError.invalid_manifest(self) if self.invalid?

    messages = []
    parser.load(data, data_root).each_with_index do |record, record_index|
      begin
        message = MESSAGE_TEMPLATE.deep_dup
        fields_for(device).each do |field|
          field.apply_to record, message, device
        end

        messages << message
      rescue ManifestParsingError => err
        err.record_index = record_index + 1
        raise err
      end
    end

    messages
  end

  def fields
    @fields ||=
      field_mapping.inject([]) do |all, (target_path, source)|
        all << ManifestField.for(self, target_path, source)
      end
  end

  def fields_for(device)
    return fields unless device && device.custom_mappings.present?
    mapped_fields = fields.dup
    device.custom_mappings.each do |from_field, to_field|
      from = mapped_fields.select { |f| f.target_field == from_field }.first
      to = mapped_fields.select { |f| f.target_field == to_field }.first

      if from
        mapped_fields.delete from
        mapped_fields.delete to
        mapped_fields << ManifestField.for(self, to_field, from.source)
      end
    end
    mapped_fields
  end

  def parser
    @parser ||= case data_type
    when "json"
      JsonMessageParser.new
    when "csv"
      CSVMessageParser.new metadata["source"]["separator"] || CSVMessageParser::DEFAULT_SEPARATOR
    when "headless_csv"
      HeadlessCSVMessageParser.new metadata["source"]["separator"] || CSVMessageParser::DEFAULT_SEPARATOR
    when "xml"
      XmlMessageParser.new
    else
      raise "unsupported source data type"
    end
  end

  def data_type
    (metadata["source"] || {})["type"]
  end

  def data_root
    (metadata["source"] || {})["root"]
  end

  def manifest_validation
    if self.metadata.blank?
      self.errors.add(:metadata, "can't be blank")
    else
      fields =  ["version","api_version","device_models"]
      check_fields_in_metadata(fields)
      check_api_version
    end

    check_field_mapping
    check_custom_fields

  rescue Oj::ParseError => ex
    self.errors.add(:parse_error, ex.message)
  end

  private

  def check_api_version
    unless self.metadata["api_version"] == CURRENT_VERSION
      self.errors.add(:api_version, "must be #{CURRENT_VERSION}")
    end
  end

  def check_fields_in_metadata(fields)
    m = self.metadata
    fields.each do |f|
      if m[f].blank?
        self.errors.add(:metadata, "must include #{f} field")
      end
    end
  end

  def check_field_mapping
    unless loaded_definition["field_mapping"].is_a? Hash
      self.errors.add(:field_mapping, "must be a json object")
    end
  end

  def check_custom_fields
    return if loaded_definition["custom_fields"].nil?

    if loaded_definition["custom_fields"].is_a? Array
      custom_fields.each do |custom_field|
        if field_mapping[custom_field['name']].blank?
          self.errors.add(:invalid_custom_field, ": target '#{custom_field["name"]}'. Must include a field mapping")
        end
        check_valid_type custom_field
        check_properties_of_enum_field custom_field
      end
    else
      self.errors.add(:custom_fields, "must be a json array")
    end
  end

  def check_valid_type(custom_field)
    if (custom_field["pii"].blank? || custom_field["pii"]==false)
      valid_types = ["date", "enum", "location", "string", "integer", "long", "float", "double", "boolean"]
      if(custom_field["type"].blank? || ! valid_types.include?(custom_field["type"]))
        self.errors.add(:invalid_type, ": target '#{custom_field["name"]}'. Field type must be one of 'integer', 'long', 'float', 'double', 'date', 'enum', 'location', 'boolean' or 'string'")
      end
    end
  end

  def check_properties_of_enum_field custom_field
    if custom_field["type"] == "enum"
      if (custom_field["options"])
        verify_absence_of_null_string custom_field
        # TODO: validate source mappings
        if (custom_field["value_mappings"])
          check_value_mappings custom_field
        end
      else
        self.errors.add(:enum_fields, "must be provided with options. (In '#{custom_field["name"]}'")
      end
    end
  end

  def verify_absence_of_null_string custom_field
    if custom_field["options"].include? NULL_STRING
      self.errors.add(:string_null, ": cannot appear as a possible value. (In '#{custom_field["name"]}') ")
    end
  end

  def check_value_mappings(custom_field)
    valid_values = custom_field["options"]
    custom_field["value_mappings"].values.each do |vm|
      if !valid_values.include? vm
        self.errors.add(:invalid_custom_field, ": target '#{custom_field["name"]}'. '#{vm}' is not a valid value")
      end
    end
  end
end
