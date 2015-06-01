class FieldScope
  attr_accessor :name, :fields

  def initialize name, fields
    @name = name
    @fields = fields.map do |definition|
      CoreField.new self, definition
    end
  end
end
