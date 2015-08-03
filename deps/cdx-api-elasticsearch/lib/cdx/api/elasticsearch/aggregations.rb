class Cdx::Api::Elasticsearch::Aggregations
  def initialize grouping_details
    @nested_grouping_details, @non_nested_grouping_details = grouping_details.partition {|g| g.nested?}
    @aggregations = Hash.new
    @last = @aggregations

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
    process @nested_grouping_details if @nested_grouping_details.present?
  end

  def process_non_nested
    process @non_nested_grouping_details if @non_nested_grouping_details.present?
  end

  def process grouping_details
    if grouping_details.first.nested?
      process_last count: {nested: {path: grouping_details.first.name} }
    end

    grouping_details.each do |grouping_detail|
      process_last create_grouping_for(grouping_detail)
    end
  end

  def create_grouping_for grouping_detail
    grouping_detail.to_es
  end

  def process_last field
    @last[:aggregations] = field
    @last = field[:count]
  end
end
