class Manifest < ActiveRecord::Base
  has_and_belongs_to_many :device_models

  validate :manifest_validation
  before_save :update_models
  before_save :update_version
  before_save :update_api_version
  after_save :update_mappings

  COLLECTION_SPLIT_TOKEN = "[*]."
  PATH_SPLIT_TOKEN = "."

  NULL_STRING = "null"

  #TODO Refiy the assay and delegate this to mysql.
  ####################################################################################################
  def self.find_by_assay_name assay_name
    manifests = self.all.select do |manifest|
      manifest.find_assay_name assay_name
    end
    raise ActiveRecord::RecordNotFound.new "There is no manifest for assay_name: '#{assay_name}'." unless manifests.present?

    manifests.sort_by(&:version).last
  end

  def find_assay_name assay_name
    field = field_mapping.detect { |f| f["target_field"] == "assay_name" }
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
    loaded_definition["metadata"] rescue {}
  end

  def loaded_definition
    @loaded_definition ||= Oj.load(self.definition)
  end

  def apply_to(data)
    data = parser.load data
    field_mapping.inject(indexed: Hash.new, pii: Hash.new, custom: Hash.new) do |event, field|
      ManifestField.new(self, field).apply_to data, event
    end
  end

  def field_mapping
    loaded_definition.with_indifferent_access["field_mapping"]
  end

  def parser
    @parser ||= case metadata["source_data_type"]
    when "json"
      JsonEventParser.new
    when "csv"
      CSVEventParser.new
    else
      raise "unsupported source data type"
    end
  end

  def self.default_definition
    field_mapping = Event.sensitive_fields.map do |sensitive_field|
      {
        target_field: sensitive_field,
        source: {path: sensitive_field},
        core: true,
        type: 'string',
        pii: true,
        indexed: false
      }
    end

    field_mapping.concat(map(Cdx::Api.searchable_fields).flatten)
    Oj.dump metadata: {source_data_type: "json"}, field_mapping: field_mapping
  end

  private

  def self.map fields, source_prefix=""
    fields.map do |field_definition|
      field = source_prefix + field_definition[:name]
      if field_definition[:type] == "nested"
        map field_definition[:sub_fields], "#{source_prefix}#{field_definition[:name]}[*]."
      else
        {
          target_field: field,
          source: {path: field},
          type: field_definition[:type],
          core: true,
          pii: false,
          indexed: true,
          valid_values: field_definition[:valid_values]
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
        check_presence_of_target_field_and_source fm
        check_presence_of_core_field fm
        check_valid_type fm
        check_properties_of_enum_field fm
      end
    else
      self.errors.add(:field_mapping, "must be an array")
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
        self.errors.add(:enum_fields, "must be provided with options. (In '#{invalid_field(field_mapping)}'")
      end
    end
  end

  def verify_absence_of_null_string field_mapping
    if field_mapping["options"].include? NULL_STRING
      self.errors.add(:string_null, ": cannot appear as a possible value. (In '#{invalid_field(field_mapping)}') ")
    end
  end

  def invalid_field field_mapping
    field_mapping["target_field"] || (field_mapping["source"] && field_mapping["source"]["path"])
  end

  def check_presence_of_core_field field_mapping
    if (field_mapping["core"].nil?)
      self.errors.add(:invalid_field_mapping, ": target '#{invalid_field(field_mapping)}'. Mapping must include a core field")
    end
  end

  def check_presence_of_target_field_and_source field_mapping
    if (field_mapping["target_field"].blank? || field_mapping["source"].blank?)
      self.errors.add(:invalid_field_mapping, ": target '#{invalid_field(field_mapping)}'. Mapping must include target_field and source")
    end
  end

  def check_value_mappings(field_mapping)
    valid_values = field_mapping["options"]
    field_mapping["value_mappings"].values.each do |vm|
      if !valid_values.include? vm
        self.errors.add(:invalid_field_mapping, ": target '#{invalid_field field_mapping}'. '#{vm}' is not a valid value")
      end
    end
  end

  def update_mappings
    mapping_template = ElasticsearchMappingTemplate.new
    mapping_template.load
    mapping_template.update_existing_indices_with self
  end

  def check_valid_type(field_mapping)
    if (field_mapping["pii"].blank? || field_mapping["pii"]==false)
      valid_types = ["integer","date","enum","location","string"]
      if(field_mapping["type"].blank? || ! valid_types.include?(field_mapping["type"]))
        self.errors.add(:invalid_type, ": target '#{invalid_field field_mapping}'. Fields must include a type, with value 'integer', 'date', 'enum', 'location' or 'string'")
      end
    end
  end
end
