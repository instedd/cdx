require "cdx/api/elasticsearch"

module Cdx::Api
  def self.index_name
    "cdx_#{Rails.env}"
  end
end

Cdx::Api.setup do |config|
  config.index_name_pattern = Cdx::Api.index_name
  config.template_name_pattern = Cdx::Api.index_name
  config.log = Rails.env != "test"
  config.elasticsearch_url = ENV["ELASTICSEARCH_URL"]
end
