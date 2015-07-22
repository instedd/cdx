class TestResultQuery
  include Policy::Actions

  def initialize params, user
    institutions = Policy.authorize(QUERY_TEST, Institution, user, user.policies)

    if institutions.present?
      @api_query = Cdx::Api::Elasticsearch::Query.for_indices([Cdx::Api.index_name], params)
      @api_query.before_execute do
        allowed_institution_ids = institutions.map { |i| i.id.to_s }
        requested_institution_ids = Array(@api_query.params["institution.id"]).map(&:to_s)
        if requested_institution_ids.empty?
          final_institution_ids = allowed_institution_ids
        else
          final_institution_ids = requested_institution_ids.select { |id| allowed_institution_ids.include? id }
        end
        @api_query.params["institution.id"] = final_institution_ids
      end
    else
      @api_query = Cdx::Api::Elasticsearch::NullQuery.new(params)
    end
  end

  def result
    @result ||= @api_query.execute
  end

  def csv_builder
    if @api_query.grouped_by.empty?
      CSVBuilder.new result["tests"]
    else
      CSVBuilder.new result["tests"], column_names: @api_query.grouped_by.concat(["count"])
    end
  end
end
