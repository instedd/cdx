require "cdx/api/elasticsearch/local_timezone_conversion"

class Cdx::Api::Elasticsearch::Query
  attr_accessor :indices
  attr_accessor :params

  include Cdx::Api::LocalTimeZoneConversion

  DEFAULT_PAGE_SIZE = 50

  def self.for_indices indices, params
    query = new params
    query.indices = indices.join ','
    query
  end

  def initialize(params, api = Cdx::Api)
    @params = params
    @api = api
    @indices ||= Cdx::Api.index_name_pattern
  end

  def before_execute(&block)
    @before_execute ||= []
    @before_execute << block
  end

  def after_execute(&block)
    @after_execute ||= []
    @after_execute << block
  end

  def execute
    if @before_execute
      @before_execute.each do |block|
        block.call self
      end
    end

    results = query(@params)
    @current_count = results["tests"].size
    @total_count = results["total_count"]

    if @after_execute
      @after_execute.inject results do |resutls, block|
        block.call results
      end
    else
      results
    end
  end

  def next_page
    return true unless @current_count && @total_count

    return false if @current_count == 0

    current_offset = params["offset"] || 0
    return false if current_offset + @current_count >= @total_count

    params["offset"] = current_offset + @current_count
    @current_count = @total_count = nil
    true
  end

  def grouped_by
    (@params["group_by"] || "").split(',')
  end

  def elasticsearch_query
    and_conditions(process_conditions(params))
  end

  protected

  def query(params)
    query = elasticsearch_query

    if params["group_by"]
      tests = query_with_group_by(query, params["group_by"])
      if params["order_by"]
        all_orders = extract_multi_values(params["order_by"])
        all_orders.map do |order|
          tests = tests.sort_by do |test|
            test[order.delete('-')]
          end
          tests = tests.reverse if order[0] == "-"
        end
      end
      total_count = tests.inject(0) { |sum, result| sum + result["count"].to_i }
    else
      tests, total_count = query_without_group_by(query, params)
    end

    tests = @api.translate tests

    {"tests" => tests, "total_count" => total_count}
  end

  def query_without_group_by(query, params)
    sort = process_order(params)
    page_size = params["page_size"] || DEFAULT_PAGE_SIZE
    offset = params["offset"]

    es_query = {body: {query: query, sort: sort}}
    es_query[:size] = page_size if page_size.present?
    es_query[:from] = offset if offset.present?

    results = @api.search_elastic es_query.merge(index: indices)
    hits = results["hits"]
    total = hits["total"]
    results = hits["hits"].map { |hit| hit["_source"] }
    [results, total]
  end

  def process_conditions params, conditions=[]
    conditions = process_fields(@api.searchable_fields, params, conditions)
    if conditions.empty?
      [{match_all: []}]
    else
      conditions
    end
  end

  def and_conditions conditions
    return conditions.first if conditions.size == 1
    {bool: {must: conditions}}
  end

  def or_conditions conditions
    return conditions.first if conditions.size == 1
    {bool: {should: conditions}}
  end

  def process_fields fields, params, conditions=[]
    fields.inject conditions do |conditions, field_definition|
      if field_definition.nested?
        nested_conditions = self.process_fields(field_definition.sub_fields, params)
        if nested_conditions.empty?
          conditions
        else
          conditions +
          [
            {nested: {
              path: field_definition.name,
              query: and_conditions(nested_conditions),
            }}
          ]
        end
      else
        (field_definition.filter_definitions || []).inject conditions do |conditions, filter_definition|
          process_field(field_definition, filter_definition, params, conditions)
        end
      end
    end
  end

  def process_field field_definition, filter_definition, params, conditions
    if field_value = params[filter_definition["name"]]
      case filter_definition["type"]
      when "match"
        conditions.push process_match_field(field_definition.name, field_definition.type, field_value)
      when "range"
        field_value = convert_timezone_if_date(field_value)
        conditions.push range: {field_definition.name => ({filter_definition["boundary"] => field_value}.merge filter_definition["options"])}
      when "duration"
        conditions.push process_duration_field(field_definition.name, field_value)
      when "wildcard"
        conditions.push process_wildcard_field(field_definition, field_value)
      end
    end
    conditions
  end

  def process_match_field(field_name, field_type, field_value)
    process_multi_field(field_value) do |value|
      process_null(field_name, value) do
        process_single_match_field(field_name, value)
      end
    end
  end

  def process_single_match_field(field_name, field_value)
    {match: {field_name => field_value}}
  end

  def process_duration_field(field_name, field_value)
    process_multi_field(field_value) do |value|
      process_null(field_name, value) do
        process_single_duration_field(field_name, value)
      end
    end
  end

  def process_duration_field(field_name, field_value)
    {range: {"#{field_name}.in_millis" => Cdx::Field::DurationField.parse_range(field_value)}}
  end

  def process_wildcard_field(field_definition, field_value)
    process_multi_field(field_value) do |value|
      process_null(field_definition.name, value) do |variable|
        process_single_wildcard_field(field_definition, value)
      end
    end
  end

  def process_single_wildcard_field(field_definition, field_value)
    if /.*\*.*/ =~ field_value
      {wildcard: {field_definition.name => field_value}}
    else
      {match: {field_matcher(field_definition.name, field_definition.type) => field_value}}
    end
  end

  def process_multi_field(field_value, &block)
    values = extract_multi_values(field_value)
    values = values.map(&block)
    or_conditions values
  end

  def extract_multi_values(field_value)
    if field_value.is_a?(Array)
      field_value
    else
      field_value.to_s.split(",").map(&:strip)
    end
  end

  def process_null(field_name, value)
    if value == 'null'
      {filtered: {filter: { missing: { field: field_name }}}}
    elsif value == 'not(null)'
      {filtered: {filter: { exists: { field: field_name }}}}
    else
      yield
    end
  end

  def field_matcher(field_name, field_type)
     if field_type == :multi_field
       "#{field_name}.analyzed"
     else
      field_name
     end
  end

  def process_order params
    order = params["order_by"] || @api.default_sort

    all_orders = extract_multi_values(order)
    all_orders.map do |order|
      if order[0] == "-"
        order = order[1..-1]
        sorting = "desc"
      else
        sorting = "asc"
      end

      duration_field = @api.searchable_fields.detect {|field| field.scoped_name == order and field.type == "duration"}

      order = "#{order}.in_millis" if duration_field

      {order => { :order => sorting, :ignore_unmapped => true} }
    end
  end

  def query_with_group_by(query, group_by)
    group_by =
      case group_by
      when String
        group_by.to_s.split ","
      when Hash
        [group_by]
      else
        Array(group_by)
      end

    group_by = group_by.map do |field|
      name, value = extract_group_by_criteria field
      Cdx::Api::Elasticsearch::IndexedField.grouping_detail_for name, value, @api
    end

    raise "Unsupported group" if group_by.include? nil

    aggregations = Cdx::Api::Elasticsearch::Aggregations.new group_by

    test = @api.search_elastic body: aggregations.to_hash.merge(query: query, size: 0), index: indices
    if test["aggregations"]
      process_group_by_buckets(test["aggregations"], aggregations.in_order, [], {}, 0)
    else
      []
    end
  end

  def extract_group_by_criteria(field)
    field_name = field.first if field.is_a? Array and field.size == 1

    if field.is_a? Hash
      name = field.keys.first
      value = field[name]
    else
      name = field
      value = nil
    end

    [name, value]
  end

  def process_group_by_buckets(aggregations, group_by, tests, test, doc_count)
    GroupingDetail.process_buckets(aggregations, group_by, tests, test, doc_count)
  end
end
