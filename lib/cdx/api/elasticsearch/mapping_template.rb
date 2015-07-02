class Cdx::Api::Elasticsearch::MappingTemplate

  def initialize(api = Cdx::Api)
    @api = api
  end

  # put_template!
  # create_default!
  def initialize_template(template_name)
    @api.client.indices.put_template name: template_name, body: template
  end

  def template
    {
      template: @api.config.template_name_pattern,
      mappings: {
        test: mapping
      }
    }
  end

  def mapping
    elastic_mapping = {
      dynamic_templates: build_dynamic_templates,
      properties: build_properties_mapping
    }
    transform_script = build_transform_script
    elastic_mapping[:transform] = { script: transform_script } unless transform_script.empty?
    elastic_mapping
  end

  def update_indices
    @api.client.indices.put_mapping({
      index: @api.config.template_name_pattern,
      body: mapping,
      type: 'test'
    })
  rescue Elasticsearch::Transport::Transport::Errors::NotFound => ex
    nil
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

  def build_properties_mapping
    scoped_fields = Cdx.core_field_scopes.select(&:has_searchables?)

    Hash[
      scoped_fields.map { |scope|
        [ scope.name, scope.elasticsearch_mapping ]
      }
    ]
  end

  def build_transform_script
    Cdx.core_fields.inject("") { |script, field|
      field.append_to_elastic_script script
    }
  end
end
