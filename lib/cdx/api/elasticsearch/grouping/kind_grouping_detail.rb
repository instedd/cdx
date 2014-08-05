require "cdx/api/elasticsearch/grouping/grouping_detail"

class KindGroupingDetail < GroupingDetail
  attr_reader :value
  attr_reader :elements
  attr_reader :reference_table

  def initialize(name, field_definition, uri_param, value, reference_table)
    super name, field_definition, uri_param
    @value = value
    @reference_table = reference_table
    @elements = target_grouping_values    
  end

  def to_es
    {
      kind: {
        terms: {
          field: field_definition[:name], size: 0
        }
      }
    }
  end

  def preprocess_buckets(count)    
    count[:buckets].select do |bucket|
      elements.include? bucket[:key]
    end
  end

  def yield_bucket(bucket)
    {reference_table.name.singularize => bucket[:key]}
  end

  private 

  def target_grouping_values
    reference_table.name.classify.constantize.where(reference_table.query_target => value).map &reference_table.value_field.to_sym
  end
end
