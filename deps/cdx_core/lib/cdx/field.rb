class Cdx::Field
  attr_accessor :scope

  def self.for scope, name, definition
    definition = definition || {}
    field_class = case definition["type"].try(:to_s)
      when "nested"
        NestedField
      when "multi_field"
        MultiField
      when "enum"
        EnumField
      when "dynamic"
        DynamicField
      when "duration"
        DurationField
      else
        Cdx::Field
      end
    field_class.new scope, name, definition
  end

  def initialize scope, name, definition
    @scope = scope
    @name = name
    @definition = (definition || {}).freeze
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

  def dynamic?
    false
  end

  def searchable?
    @definition["searchable"]
  end

  def multiple?
    @definition["multiple"]
  end

  def scoped_name
    "#{scope.scoped_name}.#{name}"
  end

  def flatten
    self
  end

  def valid_values
    nil
  end

  def pii?
    @definition["pii"] || false
  end

  def humanize(value)
    value
  end

  def validate(value)
    nil
  end

  class NestedField < self
    def initialize scope, name, definition
      if definition["sub_fields"]
        definition["sub_fields"] = definition["sub_fields"].map do |sub_name, sub_field|
          Cdx::Field.for(self, sub_name, sub_field)
        end
      end

      super
    end

    def nested?
      true
    end

    def searchable?
      sub_fields.any? &:searchable?
    end

    def flatten
      sub_fields.map(&:flatten)
    end

    def sub_fields
      @definition["sub_fields"]
    end
  end

  class MultiField < self
  end

  class EnumField < self
    def options
      @definition["options"]
    end

    def validate(value)
      super or (if !value.nil? && !options.include?(value.to_s)
        "#{value} is not within #{scoped_name} valid options (should be one of #{options.join(', ')})"
      end)
    end
  end

  class DynamicField < self
    def dynamic?
      true
    end
  end

  class DurationField < self
    def humanize(value)
      if value.is_a?(Hash) && value.length >= 1
        "#{value.values.first} #{value.keys.first}"
      else
        super
      end
    end

    def validate(value)
      # TODO: How should duration values be stored?
    end
  end
end
