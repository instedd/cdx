class TestResultQuery < Cdx::Api::Elasticsearch::Query
  include Policy::Actions

  class << self
    private :new
  end

  def self.for params, user
    institutions = Policy.authorize(QUERY_TEST, Institution, user, user.policies).map(&:uuid)
    laboratories = Policy.authorize(QUERY_TEST, Laboratory, user, user.policies).map(&:uuid)
    devices = Policy.authorize(QUERY_TEST, Device, user, user.policies).map(&:uuid)

    if institutions.present? || laboratories.present? || devices.present?
      new params, institutions, laboratories, devices
    else
      Cdx::Api::Elasticsearch::NullQuery.new(params)
    end
  end

  def self.find_by_elasticsearch_id(id)
    doc = Cdx::Api.client.get index: Cdx::Api.index_name, type: 'test', id: id
    add_names_to([doc["_source"]]).first
  end

  def initialize(params, institutions, laboratories, devices)
    super(params)
    @institutions = institutions
    @laboratories = laboratories
    @devices = devices
  end

  def process_conditions(*args)
    query = super
    policy_conditions = {}
    policy_conditions["institution.uuid"] = @institutions if @institutions.present?
    policy_conditions["laboratory.uuid"] = @laboratories if @laboratories.present?
    policy_conditions["device.uuid"] = @devices if @devices.present?
    query << or_conditions(super(policy_conditions))
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

  private

  def self.add_names_to tests
    institutions = indexed_model tests, Institution, ["institution", "uuid"]
    laboratories = indexed_model tests, Laboratory, ["laboratory", "uuid"]
    devices = indexed_model tests, Device, ["device", "uuid"]

    tests.each do |event|
      event["institution"]["name"] = institutions[event["institution"]["uuid"]].try(:name) if event["institution"]
      event["device"]["name"] = devices[event["device"]["uuid"]].try(:name) if event["device"]
      event["laboratory"]["name"] = laboratories[event["laboratory"]["uuid"]].try(:name) if event["laboratory"]
    end
  end

  def self.indexed_model(tests, model, es_field)
    ids = tests.map { |test| es_field.inject(test) { |obj, field| obj[field] } rescue nil }.uniq
    model.where("uuid" => ids).index_by { |model| model["uuid"] }
  end
end
