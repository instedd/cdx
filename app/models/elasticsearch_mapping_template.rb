class ElasticsearchMappingTemplate

  attr_reader :manifest
  attr_reader :device_models

  delegate :template_name, to: :class

  def initialize(manifest, device_models=nil)
    @manifest = manifest
    @device_models = device_models || manifest.try(:current_models)
  end

  def self.update_all!
    ElasticsearchDefaultMappingTemplate.new.update!
    Manifest.valid.each do |manifest|
      self.new(manifest).update!
    end
  end

  def self.create_default!
    ElasticsearchDefaultMappingTemplate.new.put_template!
  end

  def self.delete_templates!
    Cdx::Api.client.indices.delete_template(name: "#{template_prefix}*")
  rescue Elasticsearch::Transport::Transport::Errors::NotFound => ex
    nil
  end

  def self.template_name(name)
    return "#{template_prefix}_#{name}"
  end

  def self.template_prefix
    "cdp_tests_template_#{Rails.env}"
  end

  def self.delete_templates_for(models)
    models.each do |model|
      Cdx::Api.client.indices.delete_template(name: template_name(model.id))
    end
  end

  def update!
    put_template!
    update_indices!
  end

  def put_template!
    mapping = mapping_for(manifest)
    device_models.each do |model|
      Cdx::Api.client.indices.put_template name: template_name(model.id), body: {
        'template' => Cdx::Api.config.template_name_pattern,
        'mappings' => { "test_#{model.id}" => mapping }
      }
    end
  end

  def update_indices!
    mapping = mapping_for(manifest)
    device_models.each do |device_model|
      begin
        Cdx::Api.client.indices.put_mapping index_mapping(mapping, "test_#{device_model.id}")
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => ex
        nil
      end
    end
  end

  class ElasticsearchDefaultMappingTemplate < ElasticsearchMappingTemplate

    def initialize
      super(nil, [])
    end

    def put_template!
      Cdx::Api.client.indices.put_template name: template_name('default'), body: {
        'template' => Cdx::Api.config.template_name_pattern,
        'mappings' => {
          "_default_" => default_mapping,
          "test" => empty_mapping
        }
      }
    end

    def update_indices!
      Cdx::Api.client.indices.put_mapping index_mapping(default_mapping, '_default_')
      Cdx::Api.client.indices.put_mapping index_mapping(empty_mapping, 'test')
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => ex
      nil
    end

    def default_mapping
      {
        'dynamic_templates' => build_default_dynamic_templates,
        'properties' => build_default_properties_mapping,
      }
    end

    def empty_mapping
      {
        'dynamic_templates' => [],
        'properties' => {}
      }
    end

    def build_default_properties_mapping
      map_fields(Manifest.default.flat_mappings.select do |mapping|
        mapping[:indexed]
      end)
    end

    def build_default_dynamic_templates
      build_dynamic_templates_for Manifest.default
    end

  end

  protected

  def index_mapping(body, type)
    {
      index: Cdx::Api.config.template_name_pattern,
      body: body,
      type: type
    }
  end

  def mapping_for(manifest)
    {
      'dynamic_templates' => build_dynamic_templates_for(manifest),
      'properties' => build_properties_mapping_for(manifest),
    }
  end

  def build_dynamic_templates_for manifest
    templates = []

    manifest.flat_mappings.each do |mapping|
      if mapping['type'] == "location"
        field_name = mapping['target_field']
        template = {
          "#{field_name}_levels" => {
            "path_match" => "#{field_name}.admin_level_*",
            "mapping" =>    { "type" => "string", 'index' => 'not_analyzed'}
          }
        }
        templates << template
      end
    end

    templates
  end

  def build_properties_mapping_for manifest
    mappings = map_fields(manifest.flat_mappings.select do |mapping|
      mapping[:indexed] && !mapping[:core]
    end)
    custom_fields = {"custom_fields" => {'type' => 'nested', 'properties' => mappings}}
    Cdx::Api.searchable_fields.select(&:nested?).each do |field|
      custom_nested_fields = mappings.delete(field.name)
      if custom_nested_fields
        custom_nested_fields['properties'] = { "custom_fields" => {'type' => 'nested', 'properties' => custom_nested_fields['properties']}}
        custom_fields[field.name] = custom_nested_fields
      end
    end
    custom_fields
  end

  def map_fields fields
    fields.inject({}) do |properties, field|
      map_field properties, field
    end
  end

  def map_field properties, field
    field_names = field[:target_field].split(Manifest::COLLECTION_SPLIT_TOKEN)
    if field_names.size > 1
      target_field = properties[field_names.first] ||= {'type' => 'nested', 'properties' => Hash.new}
      sub_field = field.clone
      sub_field[:target_field] = field_names[1..-1].join(Manifest::COLLECTION_SPLIT_TOKEN)
      map_field(target_field['properties'], sub_field)
    else
      field_name = field_names.first
      field_body =
      case field['type']
      when "multi_field"
        properties[field_name] = {
          'type' => 'string',
          'index' => 'not_analyzed',
          'fields' => {
            'analyzed' => {'type' => 'string', 'index' => 'analyzed'}
          }
        }
      when "location"
        properties["#{field_name}_id"] = { 'type' => 'string', 'index' => 'not_analyzed' }
        properties["parent_#{field_name.pluralize}"] = { 'type' => 'string', 'index' => 'not_analyzed' }
        properties[field_name] = { 'type' => 'nested' }
      when "enum"
        properties[field_name] = {'type' => "string", 'index' => 'not_analyzed'}
      else
        properties[field_name] = {'type' => field[:type], 'index' => 'not_analyzed'}
      end
    end
    properties
  end
end
