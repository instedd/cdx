class ElasticsearchMappingTemplate
  def load
    Cdx::Api.client.indices.put_template name: "cdx_events_template", body: template
  end

  def update_existing_indices_with manifest
    mapping = {
      index: Cdx::Api.config.template_name_pattern,
      type: "event_#{manifest.id}",
      body: {
        dynamic_templates: build_dynamic_templates_for(manifest),
        properties: build_properties_mapping_for(manifest),
      }
    }
    Cdx::Api.client.indices.put_mapping mapping
  rescue Elasticsearch::Transport::Transport::Errors::NotFound => ex
    # do nothing. if no index match with the patern is because no event was indexed yet.
  end

  def template
    {
      'template' => Cdx::Api.config.template_name_pattern,
      'mappings' => mappings
    }
  end

  def mappings
    mappings = {
      '_default_' => {
        'dynamic_templates' => build_default_dynamic_templates,
        'properties' => build_default_properties_mapping,
      },
      'event' => {
        'dynamic_templates' => [],
        'properties' => {},
      }
    }

    Manifest.valid.each do |manifest|
      mappings["event_#{manifest.id}"] = {
        'dynamic_templates' => build_dynamic_templates_for(manifest),
        'properties' => build_properties_mapping_for(manifest),
      }
    end

    mappings
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

  def build_default_properties_mapping
    map_fields(Manifest.default.flat_mappings.select do |mapping|
      mapping[:indexed]
    end)
  end

  def build_default_dynamic_templates
    build_dynamic_templates_for Manifest.default
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
          'type' => field[:type],
          'fields' => {
            'analyzed' => {'type' => 'string', 'index' => 'analyzed'},
            field_name => {'type' => 'string', 'index' => 'not_analyzed'}
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
