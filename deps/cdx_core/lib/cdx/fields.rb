class Cdx::Fields
  def self.test
    self["test"]
  end

  def self.encounter
    self["encounter"]
  end

  def self.[](entity_name)
    @fields ||= {}
    @fields[entity_name] ||= new(entity_name)
  end

  attr_reader :entity_name

  def initialize(entity_name)
    @entity_name = entity_name
  end

  def core_fields
    @core_fields ||= core_field_scopes.map(&:flatten).flatten
  end

  def first_level_core_fields
    @first_level_core_fields ||= core_field_scopes.map(&:fields).flatten
  end

  def core_field_scopes
    @scopes ||= YAML.load_file(File.join(File.dirname(__FILE__), "..", "config", "fields.yml"))[@entity_name].map do |scope_name, definition|
      Cdx::Scope.new(scope_name, definition)
    end
  end

  def result_name
    @entity_name.pluralize
  end
end