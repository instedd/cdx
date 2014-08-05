require "bundler/setup"
require "cdx/api/elasticsearch"
require "pry-byebug"

Cdx::Api.setup do |config|
  config.index_name_pattern = "cdx_events"
  # config.log = true

end

Cdx::Api.client.indices.delete index: "cdx_events" rescue nil
Cdx::Api.initialize_default_template "cdx_events_template"
