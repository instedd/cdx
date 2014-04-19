defmodule Cdp.TestResult do
  use Timex
  use Ecto.Model
  import Tirexs.Bulk
  import Tirexs.Search

  queryable "test_results" do
    belongs_to(:device, Cdp.Device)
    field :created_at, :datetime
    field :updated_at, :datetime
    field :data, :binary
  end

  def create_in_db(device, data) do
    now = Cdp.DateTime.now
    test_result = Cdp.TestResult.new [
      device_id: device.id,
      data: data,
      created_at: now,
      updated_at: now,
    ]
    Cdp.Repo.create(test_result)
  end

  def create_in_elasticsearch(device, json_data) do
    laboratory = device.laboratory.get
    institution_id = laboratory.institution_id

    {:ok, data} = JSON.decode json_data
    data = Dict.put data, :type, "test_result"
    data = Dict.put data, :created_at, (DateFormat.format!(Date.now, "{ISO}"))
    data = Dict.put data, :device_id, device.id
    data = Dict.put data, :laboratory_id, device.laboratory_id
    data = Dict.put data, :institution_id, institution_id

    settings = Tirexs.ElasticSearch.Config.new()
    Tirexs.Bulk.store [index: Cdp.Institution.elasticsearch_index_name(institution_id), refresh: true], settings do
      create data
    end
  end

  # def enqueue_in_rabbit(device, data) do
  #   subscribers = Cdp.Subscriber.find_by_institution_id(device.institution_id)

  #   amqp_config = Cdp.Dynamo.config[:rabbit_amqp]
  #   amqp = Exrabbit.Utils.connect
  #   channel = Exrabbit.Utils.channel amqp
  #   Exrabbit.Utils.declare_exchange channel, amqp_config[:subscribers_exchange]
  #   Exrabbit.Utils.declare_queue channel, amqp_config[:subscribers_queue], true
  #   Exrabbit.Utils.bind_queue channel, amqp_config[:subscribers_queue], amqp_config[:subscribers_exchange]

  #   Enum.each subscribers, fn(s) ->
  #     IO.puts s.id
  #     {:ok, message} = JSON.encode([test_result: data, subscriber: s.id])
  #     Exrabbit.Utils.publish channel, amqp_config[:subscribers_exchange], "", message
  #   end
  # end

  def create_and_enqueue(device_key, data) do
    device = Cdp.Device.find_by_key(device_key)

    Cdp.TestResult.create_in_db(device, data)
    Cdp.TestResult.create_in_elasticsearch(device, data)
    # Cdp.TestResult.enqueue_in_rabbit(device, data)
  end

  def query(params) do
    conditions = []

    if since = params["since"] do
      condition = [range: [created_at: [from: since, include_lower: true]]]
      conditions = [condition | conditions]
    end

    if until = params["until"] do
      condition = [range: [created_at: [to: until, include_lower: true]]]
      conditions = [condition | conditions]
    end

    if institution_id = params["institution"] do
      condition = [match: ["institution_id": institution_id]]
      conditions = [condition | conditions]
    end

    if laboratory_id = params["laboratory"] do
      condition = [match: [laboratory_id: laboratory_id]]
      conditions = [condition | conditions]
    end

    if device_id = params["device"] do
      condition = [match: [device_id: device_id]]
      conditions = [condition | conditions]
    end

    if gender = params["gender"] do
      condition = [match: [gender: gender]]
      conditions = [condition | conditions]
    end

    if assay_code = params["assay_code"] do
      condition = [match: [assay_code: assay_code]]
      conditions = [condition | conditions]
    end

    if age_low = params["age_low"] do
      condition = [range: [age: [from: age_low, include_lower: true]]]
      conditions = [condition | conditions]
    end

    if age_high = params["age_high"] do
      condition = [range: [age: [to: age_high, include_upper: true]]]
      conditions = [condition | conditions]
    end

    if result = params["result"] do
      condition = [match: [result: result]]
      conditions = [condition | conditions]
    end

    query = [
      search: [
        query: [
          bool: [
            must: conditions
          ]
        ],
        sort: [
          [created_at: "asc"]
        ]
      ],
      index: "_all"
    ]

    result = Tirexs.Query.create_resource(query)
    result.hits
  end
end
