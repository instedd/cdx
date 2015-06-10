class Cdx::Api::Elasticsearch::Initializer

  def initialize(api)
    @api = api
  end

  def initialize_default_template(template_name)
    @api.client.indices.put_template name: template_name, body: template
  end

  def template
    {
      template: @api.config.template_name_pattern,
      mappings: {
        test: {
          dynamic_templates: build_dynamic_templates,
          properties: build_properties_mapping
        }
      }
    }
  end

  def build_dynamic_templates
    @api.searchable_fields.inject([]) { |templates, field|
      if field[:type].eql? "location"
        template = {
          "#{field[:name]}.admin_levels" => {
            path_match: "admin_level_*",
            mapping: { type: :string, index: :not_analyzed }
          }
        }
        templates << template
      end
      templates
    }
  end

  def build_properties_mapping
    map_fields @api.searchable_fields
  end

  def map_fields fields
    fields.inject({}) do |properties, field|
      map_field properties, field
    end
  end

  def map_field properties, field
    current = if (paths = field[:name].split('.')).size > 1
      paths[0..-2].inject properties do |current, path|
        (current[path] ||= { properties: {} })[:properties]
      end
    else
      properties
    end

    case field[:type]
    when "nested"
      current[paths.last] = {type: :nested, properties: map_fields(field[:sub_fields])}
    when "location"
      {
        paths.last => {
          "id" => { type: :string, index: :not_analyzed },
          "parents" => { type: :string, index: :not_analyzed },
          "admin_levels" => {}
        }
      }
    else
      field_body =
        case field[:type]
        when "multi_field"
          {
            fields: {
              analyzed: {type: :string, index: :analyzed},
              field[:name] => {type: :string, index: :not_analyzed}
            }
          }
        else
          {index: :not_analyzed}
        end
      current[paths.last] = {type: field[:type]}.merge(field_body)
    end
    properties
  end
end
