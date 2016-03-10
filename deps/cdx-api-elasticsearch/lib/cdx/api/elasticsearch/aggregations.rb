class Cdx::Api::Elasticsearch::Aggregations
  def initialize(grouping_details, params)
    @nested_grouping,
    @non_nested_grouping = grouping_details.partition(&:nested?)
    @aggregations = {}
    @last = @aggregations
    @params = params

    process_non_nested_grouping
    process_nested_grouping
  end

  def to_hash
    @aggregations
  end

  def in_order
    @non_nested_grouping + @nested_grouping
  end

  private

  def process_nested_grouping
    return unless @nested_grouping.present?
    process @nested_grouping
  end

  def process_non_nested_grouping
    process @non_nested_grouping if @non_nested_grouping.present?
  end

  def process(grouping_details)
    if grouping_details.first.nested?
      append_to_last count: { nested: { path: grouping_details.first.name } }
      add_nested_filters
    end

    grouping_details.each do |grouping_detail|
      append_to_last create_grouping_for(grouping_detail)
    end
  end

  def add_nested_filters
    return unless nested_filters.present?

    filters = nested_filters.inject [] do |conditions, field|
      conditions << conditions_for(field)
      conditions
    end

    append_filter_to_last(filters)
  end

  def create_grouping_for(grouping_detail)
    grouping_detail.to_es
  end

  def append_to_last(field)
    @last[:aggregations] = field
    @last = field[:count]
  end

  def append_filter_to_last(filters)
    field = {
      filtered: {
        filter: Cdx::Api::Elasticsearch::Query.and_conditions(filters)
      }
    }

    @last[:aggregations] = field
    @last = field[:filtered]
  end

  def nested_filters
    @nested_filters ||=
      Cdx::Fields.test.flattened_searchable_fields.select do |field|
        @params[field.scoped_name] && field.inside_nested?
      end
  end

  def conditions_for(field)
    Cdx::Api::Elasticsearch::Query.process_multi_field_with_nulls(
      field.scoped_name,
      @params[field.scoped_name]
    ) do |value|
      { term: { field.scoped_name => value } }
    end
  end
end
