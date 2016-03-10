class Cdx::Api::Elasticsearch::NullQuery
  def initialize(params, fields)
    @params = params
    @result_name = fields.result_name
  end

  def execute
    {@result_name => [], "total_count" => 0}
  end

  def grouped_by
    @params["group_by"].split(',')
  end

  def elasticsearch_query
    nil
  end
end
