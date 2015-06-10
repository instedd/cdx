require "cdx/version"
require "cdx/field"
require "cdx/scope"

module Cdx
  def self.core_fields
    @core_fields ||= YAML.load_file(File.join(File.dirname(__FILE__), "config", "fields.yml")).map do |scope_name, fields|
      Scope.new(scope_name, fields)
    end
  end
end
