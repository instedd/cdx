class Cdx::Field
  attr_accessor :scope

  def initialize scope, definition
    @scope = scope
    @definition = definition.with_indifferent_access

    if @definition[:sub_fields]
      @definition[:sub_fields] = @definition[:sub_fields].map do |field|
        self.class.new(self, field)
      end
    end

    @definition.freeze
  end

  def type
    @definition[:type] || 'string'
  end

  def root_scope
    scope.root_scope
  end

  def name
    @definition[:name]
  end

  def nested?
    type == 'nested'
  end

  def searchable?
    @definition[:searchable]
  end

  def sub_fields
    @definition[:sub_fields]
  end

  def has_searchables?
    searchable? or (nested? and sub_fields.any? &:searchable?)
  end

  def scoped_name
    "#{scope.scoped_name}.#{name}"
  end

  def flatten
    sub_fields || self
  end

  def valid_values
    @definition[:valid_values]
  end

  def options
    @definition[:options]
  end

  def pii?
    @definition[:pii] || false
  end
end
