require "active_support/core_ext/hash"
require "yaml"
require "elasticsearch"

module Cdx
  module Api
    module Elasticsearch
    end
  end
end

Dir[File.expand_path("../elasticsearch/**/*.rb", __FILE__)].each do |file|
  require file
end

module Cdx::Api
  class << self
    def setup
      yield Cdx::Api::Elasticsearch::Config
    end

    def initialize_default_template(template_name)
      Cdx::Api::Elasticsearch::Initializer.initialize_default_template(template_name)
    end

    def query(params)
      Cdx::Api::Elasticsearch::EventFiltering.query(params)
    end

    def sensitive_fields
      Cdx::Api::Elasticsearch::Config.sensitive_fields
    end

    def searchable_fields
      Cdx::Api::Elasticsearch::Config.searchable_fields
    end

    def index_name_pattern
      Cdx::Api::Elasticsearch::Config.index_name_pattern
    end

    def default_sort
      Cdx::Api::Elasticsearch::Config.default_sort
    end

    def search_elastic body
      if index_name_pattern
        client.search(index: index_name_pattern, body: body)
      else
        raise "You must define the index_name_pattern: Cdx::Api::Elasticsearch.setup { |config| config.index_name_pattern = ... }"
      end
    end

    def client
      log_enabled = !!Cdx::Api::Elasticsearch::Config.log
      ::Elasticsearch::Client.new log: log_enabled
    end

    def elastic_index_pattern
      Settings.cdx_elastic_index_pattern
    end
  end
end
