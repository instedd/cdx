class GroupingDetail
  attr_reader :name
  attr_reader :field_definition

  def initialize(name, field_definition)
    @name = name
    @field_definition = field_definition
  end

  def nested?
    false
  end

	def self.for(indexed_field, field_name, values)    
    if indexed_field.nested?
      NestedGroupingDetail.create indexed_field, field_name, values
    else
      grouping = nil

      definition = indexed_field.group_definitions.detect do |definition|
        definition[:name] == field_name
      end

      if definition        
        grouping_def = definition.clone
        
        if grouping_def[:type] == "range"
          if values
            grouping = RangeGroupingDetail.new indexed_field.name, indexed_field.definition, values
          end
        end

        if grouping_def[:type] == "kind"
          reference_table = ReferenceTable.new grouping_def[:reference_table][:name], grouping_def[:reference_table][:query_target], grouping_def[:reference_table][:value_field]
          grouping = KindGroupingDetail.new indexed_field.name, indexed_field.definition, values, reference_table
        end

        if !grouping
          if grouping_def[:type] == "date"
            grouping = DateGroupingDetail.new indexed_field.name, indexed_field.definition
          else
            grouping = FlatGroupingDetail.new indexed_field.name, indexed_field.definition    
          end
        end

        grouping
      end
    end
  end

  def self.process_buckets(aggregations, group_by, events, event, doc_count)
    count = aggregations[:count] || aggregations[:kind]

    if count
      if group_by.is_a? Array
        head = group_by.first
        rest = group_by[1..-1]
      else
        head = group_by
        rest = []
      end

      buckets = head.preprocess_buckets count
      head.process_bucket rest, events, event, buckets
    else
      event[:count] = doc_count
      events + [event]
    end
  end

  def preprocess_buckets(count)
    count[:buckets]
  end

  def process_bucket(group_by, events, event, buckets)
    buckets.inject events do |events, bucket|
      event = event.merge yield_bucket(bucket)
      GroupingDetail.process_buckets bucket, group_by, events, event, bucket[:doc_count]
    end
  end
end

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

class DateGroupingDetail < GroupingDetail
  attr_reader :interval

  def initialize(name, field_definition, interval)
    super name, field_definition
    @interval = interval
  end

  def to_es
    format = case grouping_detail[:interval]
      when "year"
        "yyyy"
      when "month"
        "yyyy-MM"
      when "week"
        "yyyy-'W'w"
      when "day"
        "yyyy-MM-dd"
      else
        raise "Invalid time interval: #{field[:interval]}"
    end
    
    {count: {date_histogram: {field: field_definition[:name], interval: interval, format: format}}}
  end

  def yield_bucket(bucket)
    {field_definition[:name] => bucket[:key_as_string]}
  end
end

class KindGroupingDetail < GroupingDetail
  attr_reader :value
  attr_reader :elements
  attr_reader :reference_table

  def initialize(name, field_definition, value, reference_table)
    super name, field_definition
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

class FlatGroupingDetail < GroupingDetail
  def initialize(name, field_definition)
    super name, field_definition
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
    {name => bucket[:key]}
  end
end

class RangeGroupingDetail < GroupingDetail
  attr_reader :ranges

  def initialize(name, field_definition, ranges)
    super name, field_definition
    @ranges = ranges
  end

  def to_es
    {
      count: {
        range: {
          field: field_definition[:name], ranges: ranges_to_es 
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
    {name => [normalize(bucket[:from]), normalize(bucket[:to])]}
  end

  def normalize(value)
    return value.round if value.is_a? Float and value.round == value
    value
  end
end

class NestedGroupingDetail < GroupingDetail
  attr_reader :child_grouping

  def initialize(name, field_definition, child_grouping)
    super name, field_definition
    @child_grouping = child_grouping
  end

  def nested?
    true
  end

  def to_es
    {
      count: {
        terms: {
          field: "#{field[:name]}.#{field[:sub_fields][:name]}"
        }
      }
    }
  end

  def preprocess_buckets(count)
    (count[:count] || count)[:buckets]
  end

  def yield_bucket(bucket)
    {child_grouping.name => bucket[:key]}
  end

  def self.create(indexed_field, child_field_name, values)
    child_grouping = indexed_field.sub_fields.detect do |field|
      GroupingDetail.for field, child_field_name, values
    end

    NestedGroupingDetail.new(indexed_field.name, indexed_field.definition, children_groupings) if child_grouping
  end
end