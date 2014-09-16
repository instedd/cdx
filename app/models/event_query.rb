class EventQuery
  include Policy::Actions

  def initialize params, user
    institutions = Policy.authorize(QUERY_EVENT, Institution, user, user.policies)

    indices = institutions.map &:elasticsearch_index_name

    @api_query = if indices.present?
      Cdx::Api::Elasticsearch::Query.for_indices(indices, params)
    else
      Cdx::Api::Elasticsearch::NullQuery.new(params)
    end
  end

  def result
    @result ||= @api_query.execute
  end

  def csv_builder
    if @api_query.grouped_by.empty?
      CSVBuilder.new result["events"]
    else
      CSVBuilder.new result["events"], column_names: @api_query.grouped_by.concat(["count"])
    end
  end
end
