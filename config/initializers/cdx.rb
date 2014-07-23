require "cdx/api/elasticsearch"

Cdx::Api.setup do |config|
  config.index_name_pattern = "cdp_institution_#{Rails.env}*"
  config.log = Rails.env != "test"
end
