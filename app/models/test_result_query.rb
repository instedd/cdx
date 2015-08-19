class TestResultQuery
  include Policy::Actions

  def initialize params, user
    institutions = Policy.authorize(QUERY_TEST, Institution, user, user.policies)

    if institutions.present?
      @api_query = Cdx::Api::Elasticsearch::Query.for_indices([Cdx::Api.index_name], params)
      @api_query.before_execute do
        filter_institutions_with institutions
      end
      @api_query.after_execute do |result|
        add_names_to result, institutions
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

  private

  def filter_institutions_with institutions
    allowed_institution_ids = institutions.map &:uuid
    requested_institution_ids = Array(@api_query.params["institution.uuid"]).map(&:to_s)
    if requested_institution_ids.empty?
      final_institution_ids = allowed_institution_ids
    else
      final_institution_ids = requested_institution_ids.select { |id| allowed_institution_ids.include? id }
    end
    @api_query.params["institution.uuid"] = final_institution_ids
  end

  def add_names_to result, institutions
    tests = result["tests"]
    institutions = indexed_model tests, Institution, ["institution", "uuid"]
    laboratories = indexed_model tests, Laboratory, ["laboratory", "uuid"]
    devices = indexed_model tests, Device, ["device", "uuid"]

    tests.each do |event|
      event["institution"]["name"] = institutions[event["institution"]["uuid"]].try(:name) if event["institution"]
      event["device"]["name"] = devices[event["device"]["uuid"]].try(:name) if event["device"]
      event["laboratory"]["name"] = laboratories[event["laboratory"]["uuid"]].try(:name) if event["laboratory"]
    end
    result
  end

  def indexed_model(tests, model, es_field)
    ids = tests.map { |test| es_field.inject(test) { |obj, field| obj[field] } rescue nil }.uniq
    model.where("uuid" => ids).index_by { |model| model["uuid"] }
  end
end
