require "cdx/api/elasticsearch"

module ElasticsearchHelper
  class << self
    def client
      Cdx::Api.client
    end

    def index_prefix
      "cdp_institution_#{Rails.env}"
    end

    def template
      {
        template: "#{index_prefix}*",
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

  client.indices.put_template name: "events_index_template", body: template
end
