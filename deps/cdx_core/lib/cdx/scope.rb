class Cdx::Scope
  attr_accessor :name, :fields

  def initialize name, definition
    @name = name
    @definition = definition
    @fields = @definition['fields'].map do |name, definition|
      Cdx::Field.for self, name, definition
    end
  end

  def scoped_name
    name
  end

  def allows_custom?
    @definition['allows_custom']
  end

  def flatten
    fields.map(&:flatten)
  end

  def searchable?
    fields.any? &:searchable?
  end

  def root_scope
    self
  end
end
