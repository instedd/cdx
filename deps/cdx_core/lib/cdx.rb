require "cdx/version"
require "cdx/field"
require "cdx/scope"
require "yaml"
require "active_support/core_ext/hash"

module Cdx
  def self.core_fields
    @core_fields ||= core_field_scopes.map(&:flatten).flatten
  end

  def self.core_field_scopes
    @scopes ||= YAML.load_file(File.join(File.dirname(__FILE__), "config", "fields.yml")).map do |scope_name, fields|
      Scope.new(scope_name, fields)
    end
  end
end
