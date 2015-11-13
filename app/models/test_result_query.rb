class TestResultQuery < EntityQuery
  def self.for params, user
    policies = ComputedPolicy.applicable_policies(QUERY_TEST, TestResult, user).includes(:exceptions)
    if policies.any?
      new params, policies
    else
      Cdx::Api::Elasticsearch::NullQuery.new(params, Cdx::Fields.test)
    end
  end

  def self.find_by_elasticsearch_id(id)
    doc = Cdx::Api.client.get index: Cdx::Api.index_name, type: 'test', id: id
    add_names_to([doc["_source"]]).first
  end

  def initialize(params, policies)
    super(params, Cdx::Fields.test, policies)
  end

  def execute
    result = super
    TestResultQuery.add_names_to result["tests"]
    result
  end

  protected

  def self.add_names_to tests
    institutions = indexed_model tests, Institution, ["institution", "uuid"]
    sites = indexed_model tests, Site, ["site", "uuid"]
    devices = indexed_model tests, Device, ["device", "uuid"]

    tests.each do |test|
      test["institution"]["name"] = institutions[test["institution"]["uuid"]].try(:name) if test["institution"]
      test["device"]["name"] = devices[test["device"]["uuid"]].try(:name) if test["device"]
      test["site"]["name"] = sites[test["site"]["uuid"]].try(:name) if test["site"]
    end
  end

  def self.indexed_model(tests, model, es_field)
    ids = tests.map { |test| es_field.inject(test) { |obj, field| obj[field] } rescue nil }.uniq
    model.where("uuid" => ids).index_by { |model| model["uuid"] }
  end
end
