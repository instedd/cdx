class Manifest < ActiveRecord::Base
  has_and_belongs_to_many :device_models

  validate :manifest_validation

  before_save :update_models
  before_save :update_version
  before_save :update_api_version

  after_save     :update_mappings
  around_destroy :restore_mappings

  COLLECTION_SPLIT_TOKEN = "[*]."
  PATH_SPLIT_TOKEN = "."

  NULL_STRING = "null"

  CURRENT_VERSION = "1.1.0"

  scope :valid, -> { where(api_version: CURRENT_VERSION) }

  EVENT_TEMPLATE = {
    "event" => {"indexed" => Hash.new, "pii" => Hash.new, "custom" => Hash.new},
    "sample" => {"indexed" => Hash.new, "pii" => Hash.new, "custom" => Hash.new},
    "patient" => {"indexed" => Hash.new, "pii"=> Hash.new, "custom" => Hash.new}
  }.freeze

  #TODO Refiy the assay and delegate this to mysql.
  ####################################################################################################
  def self.find_by_assay_name assay_name
    manifests = self.valid.select do |manifest|
      manifest.find_assay_name assay_name
    end
    raise ActiveRecord::RecordNotFound.new "There is no manifest for assay_name: '#{assay_name}'." unless manifests.present?

    manifests.sort_by(&:version).last
  end

  def find_assay_name assay_name
    field = flat_mappings.detect { |f| f["target_field"] == "assay_name" }
    valid_values = []
    if field["options"]
      valid_values = field["options"]
    end
    valid_values.include? assay_name
  end
  ####################################################################################################

  def self.default
    new definition: default_definition
  end

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

  def apply_to(data)
    raise ManifestParsingError.empty_event if data.blank?
    raise ManifestParsingError.invalid_manifest(self) if self.invalid?

    events = []
    parser.load(data).each do |record|
      event = EVENT_TEMPLATE.deep_dup
      field_mapping.each do |scope, mappings|
        event = mappings.inject(event) do |event, field|
          ManifestField.new(self, field, scope).apply_to record, event
        end
      end
      events << event
    end

    events
  end

  def field_mapping
    loaded_definition.with_indifferent_access["field_mapping"]
  end

  def event_mapping
    field_mapping["event"] || []
  end

  def sample_mapping
    field_mapping["sample"] || []
  end

  def patient_mapping
    field_mapping["patient"] || []
  end

  def flat_mappings
    event_mapping + patient_mapping + sample_mapping
  end

  def parser
    @parser ||= case (metadata["source"] || {})["type"]
    when "json"
      JsonEventParser.new
    when "csv"
      CSVEventParser.new metadata["source"]["separator"] || CSVEventParser::DEFAULT_SEPARATOR
    when "headless_csv"
      HeadlessCSVEventParser.new metadata["source"]["separator"] || CSVEventParser::DEFAULT_SEPARATOR
    else
      raise "unsupported source data type"
    end
  end

  def self.default_definition
    Oj.dump({
      metadata: { source: { type: "json" } },
      field_mapping: { event: map(Cdx::Api.searchable_fields).flatten }
    })
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

  def self.map fields, source_prefix=""
    fields.map do |field_definition|
      field = source_prefix + field_definition[:name]
      if field_definition[:type] == "nested"
        map field_definition[:sub_fields], "#{source_prefix}#{field_definition[:name]}#{COLLECTION_SPLIT_TOKEN}"
      else
        {
          target_field: field,
          source: {lookup: field},
          type: field_definition[:type],
          core: true,
          pii: false,
          indexed: true,
          valid_values: field_definition[:valid_values]
        }
      end
    end
  end

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

  def update_mappings
    ElasticsearchMappingTemplate.new(self, current_models).update!
  end

  def restore_mappings
    # TODO: Add tests for restoring old mappings
    models = self.current_models
    yield

    models.each(&:reload).group_by(&:current_manifest).each do |manifest, models|
      ElasticsearchMappingTemplate.new(manifest, models).update!
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
