class Cdx::Api::Elasticsearch::Initializer
  class << self

    def initialize_default_template(template_name)
      Cdx::Api.client.indices.put_template name: template_name, body: template
    end

    def template
      {
        template: Cdx::Api::Elasticsearch::Config.index_name_pattern,
        mappings: {
          event: {
            properties: build_properties_mapping
          }
        }
      }
    end

    def build_properties_mapping
      map_fields Cdx::Api.searchable_fields
    end

    def map_fields fields
      fields.inject({}) do |properties, field|
        map_field properties, field
      end
    end

    def map_field properties, field
      properties[field[:name]] =
        if field[:type] == "nested"
          {type: :nested, properties: map_fields(field[:sub_fields])}
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
          {type: field[:type]}.merge(field_body)
        end
      properties
    end

  end
end