defmodule TestResult do
  use Timex
  use Ecto.Model
  import Tirexs.Bulk
  import Ecto.Query

  queryable "test_results" do
    belongs_to(:device, Device)
    field :created_at, :datetime
    field :updated_at, :datetime
    field :uuid
    field :raw_data, :binary
    field :sensitive_data, :binary
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
      {:created_at, :date},
      {:device_id, :integer},
      {:laboratory_id, :integer},
      {:institution_id, :integer},
      {:location_id, :integer},
      {:parent_locations, :integer},
      {:age, :integer},
      {:assay, :string},
      {:assay_name, :string},
      {:device_serial_number, :multi_field},
      {:uuid, :string},
      {:result, :string},
      {:start_time, :date},
      {:system_user, :string},
    ]
  end

  def find_by_uuid(test_result_uuid) do
    Enum.into([{"uuid", test_result_uuid}, {"pii", find_by_uuid_in_postgres(test_result_uuid).sensitive_data}], %{})
  end

  def update_pii(result_uuid, data, date \\ :calendar.universal_time()) do
    date = Ecto.DateTime.from_erl(date)

    sensitive_data = Enum.map sensitive_fields, fn field_name ->
      {field_name, data[atom_to_binary(field_name)]}
    end

    test_result = find_by_uuid_in_postgres(result_uuid)
    test_result = test_result.sensitive_data sensitive_data
    test_result = test_result.updated_at date
    test_result = encrypt(test_result)

    Repo.update(test_result)
  end

  defp find_by_uuid_in_postgres(test_result_uuid) do
    query = from t in TestResult,
      where: t.uuid == ^test_result_uuid,
      select: t
    [postgres_test_result] = Repo.all(query)
    decrypt(postgres_test_result)
  end

  def create(device_key, raw_data, date \\ :calendar.universal_time()) do
    device = Device.find_by_key(device_key)

    {:ok, data} = JSEX.decode raw_data

    uuid = :erlang.iolist_to_binary(:uuid.to_string(:uuid.uuid1()))
    create_in_db(device, data, raw_data, date, uuid)
    create_in_elasticsearch(device, data, date, uuid)
  end

  def query(params) do
    query = [bool: [must: process_conditions(params)]]

    if group_by = params["group_by"] do
      query_with_group_by(query, group_by)
    else
      query_without_group_by(query)
    end
      |> Enum.map fn test_result -> Enum.into(test_result, %{}) end
  end

  def encrypt(test_result) do
    test_result = :crypto.rc4_encrypt(encryption_key, JSEX.encode!(test_result.sensitive_data))
      |> test_result.sensitive_data
    test_result.raw_data(:crypto.rc4_encrypt(encryption_key, test_result.raw_data))
  end

  def decrypt(test_result) do
    test_result = :crypto.rc4_encrypt(encryption_key, test_result.sensitive_data)
      |> JSEX.decode!
      |> test_result.sensitive_data

    test_result.raw_data(:crypto.rc4_encrypt(encryption_key, test_result.raw_data))
  end

  # ---------------------------------------------------------
  # Private functions
  # ---------------------------------------------------------

  defp encryption_key do
    "some secure key"
  end

  defp create_in_db(device, data, raw_data, date, uuid) do
    date = Ecto.DateTime.from_erl(date)

    sensitive_data = Enum.map sensitive_fields, fn field_name ->
      {field_name, data[atom_to_binary(field_name)]}
    end

    test_result = TestResult.new [
      device_id: device.id,
      raw_data: raw_data,
      uuid: uuid,
      sensitive_data: sensitive_data,
      created_at: date,
      updated_at: date,
    ]

    test_result = encrypt(test_result)
    Repo.insert(test_result)
  end

  defp create_in_elasticsearch(device, data, date, uuid) do
    institution_id = device.institution_id

    data = Dict.drop(data, (Enum.map sensitive_fields, &atom_to_binary(&1)))

    laboratories = Enum.map device.devices_laboratories.to_list, fn dl -> dl.laboratory.get end
    case laboratories do
      [lab | t ] when t != [] ->
        laboratory_id = nil
        locations = (Enum.map [lab|t], fn lab -> Repo.get Location, lab.location_id end)
        root_location = Location.common_root(locations)
        parent_locations = Location.with_parents root_location
        if root_location do
          location_id = root_location.id
        end
      [lab | []] when lab != nil ->
        laboratory_id = lab.id
        location_id = lab.location_id
        parent_locations = Location.with_parents Repo.get(Location, lab.location_id)
      _ ->
        parent_locations = []
    end

    data = Dict.put data, :type, "test_result"
    data = Dict.put data, :created_at, (DateFormat.format!(Date.from(date), "{ISO}"))
    data = Dict.put data, :device_id, device.id
    data = Dict.put data, :location_id, location_id
    data = Dict.put data, :parent_locations, parent_locations
    data = Dict.put data, :laboratory_id, laboratory_id
    data = Dict.put data, :institution_id, institution_id
    data = Dict.put data, :uuid, uuid

    settings = Tirexs.ElasticSearch.Config.new()
    Tirexs.Bulk.store [index: Institution.elasticsearch_index_name(institution_id), refresh: true], settings do
      create data
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
      ],
      index: "#{Elasticsearch.index_prefix}*"
    ]

    result = Tirexs.Query.create_resource(query)
    process_group_by_buckets(result.aggregations, all_group_by, [], [], 0)
  end

  defp process_group_by_buckets(aggregations, all_group_by, results, result, doc_count) do
    count = Dict.get(aggregations, "count")
    if count do
      buckets = count["buckets"]
      [first_group_by | other_group_by] = all_group_by
      date_captures = match_date_regex(first_group_by)
      Enum.reduce buckets, results, fn(bucket, results) ->
        if date_captures do
          {interval, field} = date_captures
          result = result ++ [{field, bucket["key_as_string"]}]
        else
          result = result ++ [{first_group_by, bucket["key"]}]
        end
        process_group_by_buckets(bucket, other_group_by, results, result, bucket["doc_count"])
      end
    else
      result = result ++ [count: doc_count]
      [result | results]
    end
  end

  def date_regex do
    ~r/\A(year|month|week|day)\(([^\)]+)\)\Z/
  end

  def match_date_regex(string) do
    captures = Regex.run(date_regex, string)
    if captures do
      [_, interval, field] = captures
      {interval, field}
    else
      nil
    end
  end

  defp process_group_by([group_by]) do
    date_captures = match_date_regex(group_by)
    if date_captures do
      {interval, field} = date_captures
      format = case interval do
                       "year"  -> "yyyy"
                       "month" -> "yyyy-MM"
                       "week"  -> "yyyy-'W'w"
                       "day"   -> "yyyy-MM-dd"
                     end
      [count: [date_histogram: [field: field, interval: interval, format: format]]]
    else
      [count: [terms: [field: group_by]]]
    end
  end

  defp process_group_by([group_by|rest]) do
    rest_aggregations = process_group_by(rest)
    group_by_aggregations = process_group_by([group_by])

    [
      count: (group_by_aggregations[:count] ++ [aggregations: rest_aggregations])
    ]
  end

  defp query_without_group_by(query) do
    query = [
      search: [
        query: query,
        sort: [[created_at: "asc"]],
      ],
      index: "#{Elasticsearch.index_prefix}*"
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

    if age = params["age"] do
      condition = [match: [age: age]]
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

    if uuid = params["uuid"] do
      condition = [match: [uuid: uuid]]
      conditions = [condition | conditions]
    end

    if Enum.empty?(conditions) do
      condition = [match_all: []]
      conditions = [condition | conditions]
    end

    conditions
  end
end
