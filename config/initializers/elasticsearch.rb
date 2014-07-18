module Elasticsearch
  require "net/http"
  require "uri"

  def self.search_all body
    client.search(index: "#{index_prefix}*", body: body)
  end

  def self.client
    if Rails.env == 'test'
      Elasticsearch::Client.new log: false
    else
      Elasticsearch::Client.new log: true
    end
  end

  def self.index_prefix
    "cdp_institution_#{Rails.env}"
  end

  def self.default_uri
    URI('http://localhost:9200')
  end

  def self.index_template_url
    URI("#{default_uri}/_template/events_index_template")
  end

  def self.template_as_json
    Oj.dump(({template: "#{index_prefix}*", mappings: { event: { properties: build_properties_mapping}}}), mode: :compat)
  end

  def self.build_properties_mapping
    self.map_fields Event.searchable_fields
  end

  def self.map_fields fields
    fields.inject Hash.new do |properties, field|
      map_field(properties, field)
    end
  end

  def self.map_field properties, field
    properties[field[:name]] = if field[:type] == "nested"
      {type: :nested, properties: map_fields(field[:sub_fields])}
    else
      field_body = case field[:type]
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

  http = Net::HTTP.new(default_uri.host, default_uri.port)
  req = Net::HTTP::Put.new(index_template_url)
  req.body = template_as_json
  req.content_type = 'multipart/form-data'
  response = http.request(req)
end
