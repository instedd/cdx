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
