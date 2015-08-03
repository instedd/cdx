require "active_support/core_ext/hash"
require "yaml"
require "elasticsearch"
require 'cdx'

module Cdx
  module Api
    module Elasticsearch
    end
  end
end

Dir[File.expand_path("../**/*.rb", __FILE__)].each do |file|
  require file
end

module Cdx::Api
  class << self
     private

     def service
       @service ||= Cdx::Api::Service.new
     end

     def method_missing(name, *args, &block)
       service.send(name, *args, &block)
     end
  end
end
