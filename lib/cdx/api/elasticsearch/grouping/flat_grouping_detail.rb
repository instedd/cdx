require "cdx/api/elasticsearch/grouping/grouping_detail"

class FlatGroupingDetail < GroupingDetail
  def initialize(name, field_definition, uri_param)
    super name, field_definition, uri_param
  end

  def to_es
    {
      count: {
        terms: {
          field: field_definition[:name]
        }
      }
    }
  end

  def yield_bucket(bucket)
    {uri_param => bucket[:key]}
  end
end