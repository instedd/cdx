class TestResultQuery < Cdx::Api::Elasticsearch::Query
  include Policy::Actions

  class << self
    private :new
  end

  def self.for params, user
    policies = ComputedPolicy.applicable_policies(QUERY_TEST, TestResult, user).includes(:exceptions)
    if policies.any?
      new params, policies
    else
      Cdx::Api::Elasticsearch::NullQuery.new(params)
    end
  end

  def self.find_by_elasticsearch_id(id)
    doc = Cdx::Api.client.get index: Cdx::Api.index_name, type: 'test', id: id
    add_names_to([doc["_source"]]).first
  end

  def initialize(params, policies)
    super(params)
    @policies = policies
  end

  def process_conditions(*args)
    query = super

    preloaded_uuids = preload_uuids_for(@policies)

    policies_conditions = @policies.map do |policy|
      positive  = super(conditions_for(policy, preloaded_uuids))
      negatives = policy.exceptions.map { |exception| super(conditions_for(exception, preloaded_uuids)) }

      if negatives.empty?
        positive
      else
        { bool: { must: positive, must_not: negatives } }
      end
    end

    query << or_conditions(policies_conditions)
  end

  def execute
    result = super
    TestResultQuery.add_names_to result["tests"]
    result
  end

  def csv_builder
    if grouped_by.empty?
      CSVBuilder.new execute["tests"]
    else
      CSVBuilder.new execute["tests"], column_names: grouped_by.concat(["count"])
    end
  end

  protected

  def not_conditions conditions
    return conditions.first if conditions.size == 1
    {bool: {must_not: conditions}}
  end

  private

  def conditions_for(computed_policy, preloaded_uuids)
    Hash[computed_policy.conditions.map do |field, value|
      ["#{field}.uuid", preloaded_uuids[field][value.to_i]] unless value.nil?
    end.compact]
  end

  def preload_uuids_for(policies)
    resource_ids = Hash.new { |h,k| h[k] = Set.new }
    (policies + policies.map(&:exceptions).flatten).each do |policy|
      policy.conditions.each do |field, value|
        resource_ids[field] << value.to_i
      end
    end

    Hash[resource_ids.map do |field, ids|
      [field, Hash[field.to_s.classify.constantize.where(id: ids.to_a).pluck(:id, :uuid)]]
    end]
  end

  def self.add_names_to tests
    institutions = indexed_model tests, Institution, ["institution", "uuid"]
    sites = indexed_model tests, Site, ["site", "uuid"]
    devices = indexed_model tests, Device, ["device", "uuid"]

    tests.each do |event|
      event["institution"]["name"] = institutions[event["institution"]["uuid"]].try(:name) if event["institution"]
      event["device"]["name"] = devices[event["device"]["uuid"]].try(:name) if event["device"]
      event["site"]["name"] = sites[event["site"]["uuid"]].try(:name) if event["site"]
    end
  end

  def self.indexed_model(tests, model, es_field)
    ids = tests.map { |test| es_field.inject(test) { |obj, field| obj[field] } rescue nil }.uniq
    model.where("uuid" => ids).index_by { |model| model["uuid"] }
  end
end
