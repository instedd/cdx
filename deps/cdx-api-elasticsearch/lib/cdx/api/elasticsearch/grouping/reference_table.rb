class ReferenceTable
  attr_reader :name
  attr_reader :query_target
  attr_reader :value_field

  def initialize(name, query_target, value_field)
    @name = name
    @query_target = query_target
    @value_field = value_field
  end
end