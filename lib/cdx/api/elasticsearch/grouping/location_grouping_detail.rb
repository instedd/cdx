require "cdx/api/elasticsearch/grouping/grouping_detail"

class LocationGroupingDetail < GroupingDetail
  attr_reader :value

  def initialize(name, field_definition, uri_param, value)
    super name, field_definition, uri_param
    @value = value
  end

  def to_es
    {
      count: {
        terms: {
          field: "#{field_definition.name}.admin_level_#{value}",
          size: 0
        }
      }
    }
  end

  def yield_bucket(bucket)
    { name => bucket["key"] }
  end
end
