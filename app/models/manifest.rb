class Manifest < ActiveRecord::Base
  has_and_belongs_to_many :device_models

  validate :manifest_validation

  before_save :update_models
  before_save :update_version
  before_save :update_api_version

  COLLECTION_SPLIT_TOKEN = "[*]."
  PATH_SPLIT_TOKEN = "."

  NULL_STRING = "null"

  CURRENT_VERSION = "1.1.0"

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

  def metadata
    loaded_definition["metadata"] || {}
  end

  def loaded_definition
    @loaded_definition ||= Oj.load(self.definition)
  end

  def apply_to(data, device)
    raise ManifestParsingError.empty_message if data.blank?
    raise ManifestParsingError.invalid_manifest(self) if self.invalid?

    messages = []
    parser.load(data, data_root).each_with_index do |record, record_index|
      begin
        message = MESSAGE_TEMPLATE.deep_dup
        field_mapping.each do |scope, mappings|
          message = mappings.inject(message) do |message, field|
            ManifestField.new(self, field, scope, device).apply_to record, message
          end
        end
        messages << message
      rescue ManifestParsingError => err
        err.record_index = record_index + 1
        raise err
      end
    end

    messages
  end

  def field_mapping
    loaded_definition.with_indifferent_access["field_mapping"]
  end

  def test_mapping
    field_mapping["test"] || []
  end

  def sample_mapping
    field_mapping["sample"] || []
  end

  def patient_mapping
    field_mapping["patient"] || []
  end

  def device_mapping
    device_mapping["device"] || []
  end

  def flat_mappings
    test_mapping + patient_mapping + sample_mapping
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
        self.errors.add(:metadata, "must include "+ f +" field")
      end
    end
  end

  def check_field_mapping
    if loaded_definition["field_mapping"].is_a? Hash
      flat_mappings.each do |fm|
        check_presence_of_target_field_and_source fm
        check_valid_type fm
        check_properties_of_enum_field fm
      end
    else
      self.errors.add(:field_mapping, "must be a json object")
    end
  end

  def check_properties_of_enum_field field_mapping
    if field_mapping["type"] == "enum"
      if (field_mapping["options"])
        verify_absence_of_null_string field_mapping
        # TODO: validate source mappings
        if (field_mapping["value_mappings"])
          check_value_mappings field_mapping
        end
      else
        self.errors.add(:enum_fields, "must be provided with options. (In '#{field_mapping["target_field"]}'")
      end
    end
  end

  def verify_absence_of_null_string field_mapping
    if field_mapping["options"].include? NULL_STRING
      self.errors.add(:string_null, ": cannot appear as a possible value. (In '#{field_mapping["target_field"]}') ")
    end
  end

  def check_presence_of_target_field_and_source field_mapping
    if (field_mapping["target_field"].blank? || field_mapping["source"].blank?)
      self.errors.add(:invalid_field_mapping, ": target '#{field_mapping["target_field"]}'. Mapping must include 'target_field' and 'source' fields")
    end
  end

  def check_value_mappings(field_mapping)
    valid_values = field_mapping["options"]
    field_mapping["value_mappings"].values.each do |vm|
      if !valid_values.include? vm
        self.errors.add(:invalid_field_mapping, ": target '#{field_mapping["target_field"]}'. '#{vm}' is not a valid value")
      end
    end
  end

  def check_valid_type(field_mapping)
    if (field_mapping["pii"].blank? || field_mapping["pii"]==false)
      valid_types = ["date", "enum", "location", "string", "integer", "long", "float", "double", "boolean"]
      if(field_mapping["type"].blank? || ! valid_types.include?(field_mapping["type"]))
        self.errors.add(:invalid_type, ": target '#{field_mapping["target_field"]}'. Field type must be one of 'integer', 'long', 'float', 'double', 'date', 'enum', 'location', 'boolean' or 'string'")
      end
    end
  end
end
