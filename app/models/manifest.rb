class Manifest < ActiveRecord::Base
  belongs_to :device_model, inverse_of: :manifest
  has_and_belongs_to_many :conditions

  validate :manifest_validation
  validates_presence_of :device_model

  validates_uniqueness_of :device_model

  before_save :update_version
  before_save :update_api_version
  before_save :update_conditions

  COLLECTION_SPLIT_TOKEN = "[*]."
  PATH_SPLIT_TOKEN = "."

  NULL_STRING = "null"

  CURRENT_VERSION = "1.2.1"

  scope :valid, -> { where(api_version: CURRENT_VERSION) }

  def self.new_message
    {
      TestResult.entity_scope => {"core" => {}, "pii" => {}, "custom" => {}},
      Sample.entity_scope     => {"core" => {}, "pii" => {}, "custom" => {}},
      Patient.entity_scope    => {"core" => {}, "pii" => {}, "custom" => {}},
      Encounter.entity_scope  => {"core" => {}, "pii" => {}, "custom" => {}},
    }
  end

  def reload
    @loaded_definition = nil
    super
  end

  def update_conditions
    self.conditions = Array(metadata["conditions"] || []).map { |name| Condition.find_or_create_by(name: name)}
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
    loaded_definition["field_mapping"]
  end

  def custom_fields
    (loaded_definition['custom_fields'] || [])
  end

  def apply_to(data, device)
    raise ManifestParsingError.empty_message if data.blank?
    raise ManifestParsingError.invalid_manifest(self) if self.invalid?

    messages = []
    parser.load(data, data_root).each_with_index do |record, record_index|
      begin
        message = self.class.new_message
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
    if self.definition && self.loaded_definition
      if self.metadata.blank?
        self.errors.add(:metadata, "can't be blank")
      else
        fields = %w(version api_version conditions)
        check_fields_in_metadata(fields)
        check_api_version
        check_conditions
      end

      check_field_mapping
      check_custom_fields
    else
      self.errors.add(:deifinition, "can't be blank")
    end

  rescue Oj::ParseError => ex
    self.errors.add(:parse_error, ex.message)
  end

  private

  def check_api_version
    unless self.metadata["api_version"] == CURRENT_VERSION
      self.errors.add(:api_version, "must be #{CURRENT_VERSION}")
    end
  end

  def check_conditions
    conditions = self.metadata["conditions"]
    unless conditions.is_a?(Array)
      self.errors.add(:conditions, "must be a json array")
      return
    end

    if conditions.empty?
      self.errors.add(:conditions, "must be a non-empty json array")
      return
    end

    unless conditions.all? { |condition| condition.is_a?(String) }
      self.errors.add(:conditions, "must be a json string array")
      return
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
    unless field_mapping.is_a? Hash
      self.errors.add(:field_mapping, "must be a json object")
    end
  end

  def check_custom_fields
    return if loaded_definition["custom_fields"].nil?

    if loaded_definition["custom_fields"].is_a? Hash
      custom_fields.each do |custom_field_name, custom_field|
        check_no_type custom_field_name, custom_field
      end
    else
      self.errors.add(:custom_fields, "must be a json object")
    end
  end

  def check_no_type(custom_field_name, custom_field)
    if custom_field["type"]
      self.errors.add(:invalid_type, ": target '#{custom_field_name}'. Field can't specify a type.")
    end
  end
end
