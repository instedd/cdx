require "bundler/setup"
require "cdx/api/elasticsearch"
require "pry-byebug"

require "support/elasticsearch_indices.rb"
require "support/cdx_api_helpers.rb"

Cdx::Api.setup do |config|
  config.index_name_pattern = "cdx_events*"
  config.template_name_pattern = "cdx_events*"
  config.log = false
end

Cdx::Api.client.indices.delete index: "cdx_events" rescue nil
Cdx::Api.initialize_default_template "cdx_events_template"
