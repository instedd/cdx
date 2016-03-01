class Cdx::Api::Elasticsearch::Aggregations
  def initialize(grouping_details, params)
    @nested_grouping_details, @non_nested_grouping_details = grouping_details.partition(&:nested?)
    @aggregations = {}
    @last = @aggregations
    @params = params

    process_non_nested
    process_nested
  end

  def to_hash
    @aggregations
  end

  def in_order
    @non_nested_grouping_details + @nested_grouping_details
  end

  private

  def process_nested
    return unless @nested_grouping_details.present?
    process @nested_grouping_details
  end

  def process_non_nested
    process @non_nested_grouping_details if @non_nested_grouping_details.present?
  end

  def process(grouping_details)
    if grouping_details.first.nested?
      process_last count: { nested: { path: grouping_details.first.name } }
      add_nested_filters
    end

    grouping_details.each do |grouping_detail|
      process_last create_grouping_for(grouping_detail)
    end
  end

  def add_nested_filters
    filter_over_a_nested_field = Cdx::Fields.test.core_fields.select { |field| @params[field.scoped_name] && field.scope.nested? }
    return unless filter_over_a_nested_field.present?

    filters = filter_over_a_nested_field.map do |field|
      { term: { field.scoped_name => @params[field.scoped_name] } }
    end

    field = {
      filtered: {
        filter: and_conditions(filters)
      }
    }
    @last[:aggregations] = field
    @last = field[:filtered]
  end

  def create_grouping_for(grouping_detail)
    grouping_detail.to_es
  end

  def process_last(field)
    @last[:aggregations] = field
    @last = field[:count]
  end

  def and_conditions(conditions)
    return conditions.first if conditions.size == 1
    { bool: { must: conditions } }
  end
end
