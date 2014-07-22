require "bundler/setup"
require "cdx/api/elasticsearch"
require "pry-byebug"

Cdx::Api.setup do |config|
  config.index_name_pattern = "cdx_events"
  # config.log = true
end

module SetupElasticsearch
  class << self
    def template
      {
        template: "cdx_events*",
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

  Cdx::Api.client.indices.delete index: "cdx_events" rescue nil
  Cdx::Api.client.indices.put_template name: "cdx_events_template", body: template
end
