class TestResultQuery
  include Policy::Actions

  def initialize params, user
    institutions = Policy.authorize(QUERY_TEST, Institution, user, user.policies).map(&:uuid)
    institutions = institutions & Array(params["institution.uuid"]) if params["institution.uuid"]
    params["institution.uuid"] = institutions

    devices = Policy.authorize(QUERY_TEST, Device, user, user.policies).map(&:uuid)
    devices = devices & Array(params["device.uuid"]) if params["device.uuid"]
    params["device.uuid"] = devices

    if institutions.present?
      @api_query = Cdx::Api::Elasticsearch::Query.for_indices([Cdx::Api.index_name], params)
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

  def next_page
    return true unless @result

    current_count = @result["tests"].size
    return false if current_count == 0

    current_offset = @api_query.params["offset"] || 0
    total_count = @result["total_count"]
    return false if current_offset + current_count >= total_count

    @result = nil
    @api_query.params["offset"] = current_offset + current_count
    true
  end

  def csv_builder
    if @api_query.grouped_by.empty?
      CSVBuilder.new result["tests"]
    else
      CSVBuilder.new result["tests"], column_names: @api_query.grouped_by.concat(["count"])
    end
  end

  private

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
