require "cdx/version"
require "cdx/core_field"
require "cdx/field_scope"

module Cdx
  def self.core_fields
    @core_fields ||= YAML.load_file(File.join("config/fields.yml")).map do |scope_name, fields|
      Scope.new(scope_name, fields)
    end
  end
end
