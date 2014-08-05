require "cdx/api/elasticsearch/grouping/grouping_detail"

class NestedGroupingDetail < GroupingDetail
  attr_reader :child_grouping

  def initialize(name, field_definition, uri_param, child_grouping)
    super name, field_definition, uri_param
    @child_grouping = child_grouping
  end

  def nested?
    true
  end

  def to_es
    {
      count: {
        terms: {
          field: "#{field_definition[:name]}.#{child_grouping.name}"
        }
      }
    }
  end

  def preprocess_buckets(count)
    (count[:count] || count)[:buckets]
  end

  def yield_bucket(bucket)
    {uri_param => bucket[:key]}
  end

  def self.create(indexed_field, child_field_name, values)
    child_grouping = indexed_field.sub_fields.detect do |field|
      GroupingDetail.for field, child_field_name, values
    end

    NestedGroupingDetail.new(indexed_field.name, indexed_field, child_field_name, child_grouping) if child_grouping
  end
end