class Cdx::Api::Elasticsearch::Query
  DEFAULT_PAGE_SIZE = 50

  def initialize(params, api = Cdx::Api)
    @params = params
    @api = api
  end

  def execute
    query(@params)
  end

  protected

  def query(params)
    query = and_conditions(process_conditions(params))

    if params[:group_by]
      events = query_with_group_by(query, params[:group_by])
      if params['order_by']
        all_orders = extract_multi_values(params['order_by'])
        all_orders.map do |order|
          events = events.sort_by do |event|
            event[order.delete('-')]
          end
          events = events.reverse if order[0] == "-"
        end
      end
      total_count = events.inject(0) { |sum, result| sum + result[:count].to_i }
    else
      events, total_count = query_without_group_by(query, params)
    end

    events = @api.translate events

    {"events" => events, "total_count" => total_count}
  end

  def query_without_group_by(query, params)
    sort = process_order(params)
    page_size = params[:page_size] || DEFAULT_PAGE_SIZE
    offset = params[:offset]

    es_query = {body: {query: query, sort: sort}}
    es_query[:size] = page_size if page_size.present?
    es_query[:from] = offset if offset.present?

    results = @api.search_elastic(es_query)
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
      if field_definition[:type] == "nested"
        nested_conditions = self.process_fields(field_definition[:sub_fields], params)
        if nested_conditions.empty?
          conditions
        else
          conditions +
          [
            {nested: {
              path: field_definition[:name],
              query: and_conditions(nested_conditions),
            }}
          ]
        end
      else
        (field_definition[:filter_parameter_definition] || []).inject conditions do |conditions, filter_parameter_definition|
          process_field(field_definition, filter_parameter_definition, params, conditions)
        end
      end
    end
  end

  def process_field field_definition, filter_parameter_definition, params, conditions
    if field_value = params[filter_parameter_definition[:name]]
      case filter_parameter_definition[:type]
      when "match"
        conditions.push process_match_field(field_definition[:name], field_definition[:type], field_value)
      when "range"
        conditions.push range: {field_definition[:name] => ({filter_parameter_definition[:boundary] => field_value}.merge filter_parameter_definition[:options])}
      when "wildcard"
        conditions.push process_wildcard_field(field_definition, field_value)
      when "location"
        conditions.push process_location_field(field_definition, field_value)
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

  def process_wildcard_field(field_definition, field_value)
    process_multi_field(field_value) do |value|
      process_null(field_definition[:name], value) do |variable|
        process_single_wildcard_field(field_definition, value)
      end
    end
  end

  def process_single_wildcard_field(field_definition, field_value)
    if /.*\*.*/ =~ field_value
      {wildcard: {field_definition[:name] => field_value}}
    else
      {match: {field_matcher(field_definition[:name], field_definition[:type]) => field_value}}
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

  def process_location_field(field_definition, field_value)
    process_match_field("parent_#{field_definition[:name].pluralize}", field_definition[:type], field_value)
  end

  def process_order params
    order = params["order_by"] || @api.default_sort

    all_orders = extract_multi_values(order)
    all_orders.map do |order|
      if order[0] == "-"
        {order[1..-1] => "desc"}
      else
        {order => "asc"}
      end
    end
  end

  def query_with_group_by(query, group_by)
    group_by =
      case group_by
      when String, Symbol
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

    aggregations = Cdx::Api::Elasticsearch::Aggregations.new group_by

    event = @api.search_elastic body: aggregations.to_hash.merge(query: query), size: 0
    if event["aggregations"]
      process_group_by_buckets(event["aggregations"].with_indifferent_access, aggregations.in_order, [], {}, 0)
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

  def process_group_by_buckets(aggregations, group_by, events, event, doc_count)
    GroupingDetail.process_buckets(aggregations, group_by, events, event, doc_count)
  end
end
