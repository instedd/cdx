require "cdx/api/elasticsearch/grouping/grouping_detail"

class DurationGroupingDetail < GroupingDetail
  attr_reader :ranges

  def initialize(name, field_definition, uri_param, ranges)
    raise "Can't group by duration field without ranges" unless ranges
    super name, field_definition, uri_param
    @ranges = ranges
  end

  def to_es
    {
      count: {
        range: {
          field: "#{field_definition.name}.in_millis",
          ranges: ranges_to_es
        }
      }
    }
  end

  def ranges_to_es
    ranges.map do |range|
      range_hash = Cdx::Field::DurationField.parse_range range
      range_hash["key"] = range
      range_hash
    end
  end

  def yield_bucket(bucket)
    {uri_param => bucket["key"]}
  end

  def normalize(value)
    return value.round if value.is_a? Float and value.round == value
    value
  end
end
