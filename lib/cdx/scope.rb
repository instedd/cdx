class Cdx::Scope
  attr_accessor :name, :fields

  def initialize name, fields
    @name = name
    @fields = fields.map do |definition|
      Cdx::Field.new self, definition
    end
  end
end
