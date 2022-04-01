require "cdx/api/elasticsearch"

module Cdx::Api
  def self.index_name
    if Rails.env.test?
      "cdx_#{Rails.env}#{ENV["TEST_ENV_NUMBER"]}"
    else
      "cdx_#{Rails.env}"
    end
  end

  def self.mapping_template_name
    if Rails.env.test?
      "cdx_tests_template_#{Rails.env}#{ENV["TEST_ENV_NUMBER"]}"
    else
      "cdx_tests_template_#{Rails.env}"
    end
  end
end

Cdx::Api.setup do |config|
  config.index_name_pattern = Cdx::Api.index_name
  config.template_name_pattern = Cdx::Api.index_name
  config.log = Rails.logger if Rails.env != "production"
  config.elasticsearch_url = ENV["ELASTICSEARCH_URL"]
end
