require "cdx/api/elasticsearch/grouping/grouping_detail"

class RangeGroupingDetail < GroupingDetail
  attr_reader :ranges

  def initialize(name, field_definition, uri_param, ranges)
    super name, field_definition, uri_param
    @ranges = ranges
  end

  def to_es
    {
      count: {
        range: {
          field: field_definition.name, ranges: ranges_to_es
        }
      }
    }
  end

  def ranges_to_es
    ranges.map do |range|
      if range.is_a? Hash
        range
      else
        {from: range[0], to: range[1]}
      end
    end
  end

  def yield_bucket(bucket)
    {uri_param => [normalize(bucket[:from]), normalize(bucket[:to])]}
  end

  def normalize(value)
    return value.round if value.is_a? Float and value.round == value
    value
  end
end
