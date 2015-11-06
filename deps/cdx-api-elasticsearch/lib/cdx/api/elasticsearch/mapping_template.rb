class Cdx::Api::Elasticsearch::MappingTemplate

  def initialize(api = Cdx::Api)
    @api = api
  end

  def initialize_template(template_name)
    @api.client.indices.put_template name: template_name, body: template
  end

  def template
    {
      template: @api.config.template_name_pattern,
      mappings: {
        test: mapping("test_result"),
        encounter: mapping("encounter"),
      }
    }
  end

  def mapping(entity_name)
    {
      dynamic_templates: build_dynamic_templates,
      properties: build_properties_mapping(entity_name),
    }
  end

  def build_dynamic_templates
    [
      {
        "admin_levels" => {
          path_match: "*.admin_level_*",
          mapping: { type: :string, index: :not_analyzed }
        }
      },
      {
        "custom_fields" => {
          path_match: "*.custom_fields.*",
          mapping: { enabled: false }
        }
      }
    ]
  end

  def build_properties_mapping(entity_name)
    scoped_fields = Cdx::Fields[entity_name].core_field_scopes.select(&:searchable?)

    Hash[
      scoped_fields.map { |scope|
        [ scope.name, scope.elasticsearch_mapping ]
      }
    ]
  end
end
