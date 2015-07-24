class Cdx::Field
  attr_accessor :scope

  def self.for scope, name, definition
    definition = definition || {}
    field_class = case definition["type"]
      when "nested"
        NestedField
      when "multi_field"
        MultiField
      when "enum"
        EnumField
      when "dynamic"
        DynamicField
      else
        Cdx::Field
      end
    field_class.new scope, name, definition
  end

  def initialize scope, name, definition
    @scope = scope
    @name = name
    @definition = definition || {}

    if @definition["sub_fields"]
      @definition["sub_fields"] = @definition["sub_fields"].map do |sub_name, sub_field|
        Cdx::Field.for(self, sub_name, sub_field)
      end
    end

    @definition.freeze
  end

  def type
    @definition["type"] || 'string'
  end

  def root_scope
    scope.root_scope
  end

  def name
    @name
  end

  def nested?
    false
  end

  def searchable?
    @definition["searchable"]
  end

  def sub_fields
    @definition["sub_fields"]
  end

  def has_searchables?
    searchable?
  end

  def scoped_name
    "#{scope.scoped_name}.#{name}"
  end

  def flatten
    sub_fields || self
  end

  def valid_values
    @definition["valid_values"]
  end

  def options
    @definition["options"]
  end

  def pii?
    @definition["pii"] || false
  end

  class NestedField < self
    def nested?
      true
    end

    def searchable?
      sub_fields.any? &:searchable?
    end
  end

  class MultiField < self
  end

  class EnumField < self
  end

  class DynamicField < self
  end
end
