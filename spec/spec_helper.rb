require "bundler/setup"
require "cdx/api/elasticsearch"
require "pry-byebug"

require "support/elasticsearch_indices.rb"
require "support/cdx_api_helpers.rb"

Cdx::Api.setup do |config|
  config.index_name_pattern = "cdx_tests*"
  config.template_name_pattern = "cdx_tests*"
  config.log = false
end

Cdx::Api.client.indices.delete index: "cdx_tests" rescue nil
Cdx::Api.initialize_default_template "cdx_tests_template"
