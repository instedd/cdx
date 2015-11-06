class Cdx::Api::Elasticsearch::MultiQuery
  def initialize(params_list_or_queries, fields, result_name, api = Cdx::Api)
    @queries = params_list_or_queries.map do |params_or_query|
      if params_or_query.respond_to?(:execute)
        params_or_query
      else
        Cdx::Api::Elasticsearch::Query.new(params_or_query, fields, result_name, api)
      end
    end
  end

  def execute
    @queries.map(&:execute)
  end
end
