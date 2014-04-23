defmodule Cdp.TestResult do
  use Timex
  use Ecto.Model
  import Tirexs.Bulk

  queryable "test_results" do
    belongs_to(:device, Cdp.Device)
    field :created_at, :datetime
    field :updated_at, :datetime
    field :raw_data, :binary
    field :sensitive_data, :binary
  end

  def create_in_db(device, data, raw_data) do
    now = Cdp.DateTime.now

    sensitive_data = Enum.map sensitive_fields, fn field_name ->
      {field_name, data[field_name]}
    end

    test_result = Cdp.TestResult.new [
      device_id: device.id,
      raw_data: raw_data,
      sensitive_data: sensitive_data,
      created_at: now,
      updated_at: now,
    ]

    test_result = encrypt(test_result)
    Cdp.Repo.create(test_result)
  end

  def find_by_id(test_result_id) do
    query = from t in Cdp.TestResult,
      where: t.id == ^test_result_id,
      select: t
    [test_result] = Cdp.Repo.all(query)
    test_result = decrypt(test_result)
    test_result
  end

  def create_in_elasticsearch(device, data) do
    laboratory = device.laboratory.get
    institution_id = laboratory.institution_id

    data = Dict.drop(data, (Enum.map sensitive_fields, &atom_to_binary(&1)))

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

  def create_and_enqueue(device_key, raw_data) do
    device = Cdp.Device.find_by_key(device_key)

    {:ok, data} = JSON.decode raw_data

    Cdp.TestResult.create_in_db(device, data, raw_data)
    Cdp.TestResult.create_in_elasticsearch(device, data)
    # Cdp.TestResult.enqueue_in_rabbit(device, data)
  end

  def query(params) do
    query = [bool: [must: process_conditions(params)]]

    if group_by = params["group_by"] do
      query_with_group_by(query, group_by)
    else
      query_without_group_by(query)
    end
  end

  defp query_with_group_by(query, group_by) do
    all_group_by = String.split(group_by, ",")
    aggregations = process_group_by(all_group_by)

    query = [
      search: [
        query: query,
        aggregations: aggregations,
        size: 0
      ]
    ]

    result = Tirexs.Query.create_resource(query)
    process_group_by_buckets(result.aggregations, all_group_by, [], [], 0)
  end

  defp process_group_by_buckets(aggregations, all_group_by, results, result, doc_count) do
    count = Dict.get(aggregations, "count")
    if count do
      buckets = count["buckets"]
      Enum.reduce buckets, results, fn(bucket, results) ->
        [first_group_by | other_group_by] = all_group_by
        result = result ++ [{first_group_by, bucket["key"]}]
        process_group_by_buckets(bucket, other_group_by, results, result, bucket["doc_count"])
      end
    else
      result = result ++ [count: doc_count]
      [result | results]
    end
  end

  defp process_group_by([group_by]) do
    [count: [terms: [field: group_by]]]
  end

  defp process_group_by([group_by|rest]) do
    aggregations = process_group_by(rest)
    [
      count: [terms: aggregations[:count][:terms]] ++
        [aggregations: process_group_by([group_by])]
    ]
  end

  defp query_without_group_by(query) do
    query = [
      search: [
        query: query,
        sort: [[created_at: "asc"]],
      ],
      index: "_all"
    ]
    result = Tirexs.Query.create_resource(query)
    Enum.map result.hits, fn(hit) -> hit["_source"] end
  end

  defp process_conditions(params) do
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

    if assay_name = params["assay_name"] do
      condition = [match: [assay_name: assay_name]]
      conditions = [condition | conditions]
    end

    if min_age = params["min_age"] do
      condition = [range: [age: [from: min_age, include_lower: true]]]
      conditions = [condition | conditions]
    end

    if max_age = params["max_age"] do
      condition = [range: [age: [to: max_age, include_upper: true]]]
      conditions = [condition | conditions]
    end

    if result = params["result"] do
      condition = [match: [result: result]]
      conditions = [condition | conditions]
    end

    if Enum.empty?(conditions) do
      condition = [match_all: []]
      conditions = [condition | conditions]
    end

    conditions
  end

  def encrypt(test_result) do
    {:ok, json_data} = JSON.encode(test_result.sensitive_data)
    test_result = test_result.sensitive_data(json_data)
    test_result = test_result.sensitive_data(:crypto.rc4_encrypt(encryption_key, test_result.sensitive_data))
    test_result.raw_data(:crypto.rc4_encrypt(encryption_key, test_result.raw_data))
  end

  def decrypt(test_result) do
    test_result = test_result.sensitive_data(:crypto.rc4_encrypt(encryption_key, test_result.sensitive_data))
    {:ok, data} = JSON.decode(test_result.sensitive_data)
    test_result = test_result.sensitive_data(data)
    test_result.raw_data(:crypto.rc4_encrypt(encryption_key, test_result.raw_data))
  end

  defp encryption_key do
    "some secure key"
  end

  def sensitive_fields do
    [
      :patient_id,
      :patient_name,
      :patient_telephone_number,
      :patient_zip_code,
    ]
  end

  def serchable_fields do
    [
      {:assay, :string},
      {:assay_name, :string},
      {:device_serial_number, :multi_field},
      {:guid, :string},
      {:institution_id, :integer},
      {:laboratory_id, :integer},
      {:location_id, :integer},
      {:parent_locations, :integer},
      {:result, :string},
      {:start_time, :date},
      {:system_user, :string},
      {:age, :integer},
      {:device_id, :integer},
      {:type, :string},
      {:created_at, :date},
      {:device_id, :integer},
      {:laboratory_id, :integer},
      {:institution_id, :integer},
    ]
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
end
