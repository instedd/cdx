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
        nested: { path: "location" },
        aggregations: {
            "admin_level_#{value}" => {
                terms: { field: "location.admin_level_#{value}", size: 0 }
            }
        }
      }
    }
  end

  def preprocess_buckets(count)    
    count["admin_level_#{value}"][:buckets]
  end

  def yield_bucket(bucket)
    { "location" => bucket[:key] }
  end

end
