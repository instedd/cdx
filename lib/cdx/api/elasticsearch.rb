require "cdx/api/elasticsearch/version"

module Cdx
  module Api
    module Elasticsearch
      module Concerns
      end
    end
  end
end

Dir[File.expand_path("../elasticsearch/**/*.rb", __FILE__)].each do |file|
  require file
end

module Cdx::Api

  include Cdx::Api::Elasticsearch::Concerns::EventFieldDefinition
  include Cdx::Api::Elasticsearch::Concerns::EventFiltering
  include Cdx::Api::Elasticsearch::Concerns::EventGrouping

  def self.search_elastic body
    client.search(index: elastic_index_pattern, body: body)
  end

  def self.client
    if Rails.env == 'test'
      ::Elasticsearch::Client.new log: false
    else
      ::Elasticsearch::Client.new log: true
    end
  end

  def self.elastic_index_pattern
    Settings.cdx_elastic_index_pattern
  end

end
