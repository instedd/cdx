class Cdx::Api::Elasticsearch::NullQuery
  def initialize(params)
    @params = params
  end

  def execute
    {"tests" => [], "total_count" => 0}
  end

  def grouped_by
    @params["group_by"].split(',')
  end

  def elasticsearch_query
    nil
  end
end
