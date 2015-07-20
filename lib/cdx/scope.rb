class Cdx::Scope
  attr_accessor :name, :fields

  def initialize name, fields
    @name = name
    @fields = fields.map do |definition|
      Cdx::Field.new self, definition
    end
  end

  def scoped_name
    name
  end

  def flatten
    @fields
  end

  def has_searchables?
    fields.any? &:searchable?
  end

  def root_scope
    self
  end
end
