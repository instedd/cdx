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

  def searchable_fields do
    [
      {:created_at, :date, [
        {"since", {:range, [:from, {:include_lower, true}]}},
        {"until", {:range, [:to, {:include_lower, true}]}}
      ]},
      {:device_uuid, :string, [{"device", :match}]},
      {:laboratory_id, :integer, [{"laboratory", :match}]},
      {:institution_id, :integer, [{"institution", :match}]},
      {:location_id, :integer, []},
      {:parent_locations, :integer, [{"location", :match}]},
      {:age, :integer, [
        {"age", :match},
        {"min_age", {:range, [:from, {:include_lower, true}]}},
        {"max_age", {:range, [:to, {:include_upper, true}]}},
      ]},
      {:assay_name, :string, [{"assay_name", :wildcard}]},
      {:device_serial_number, :string, []},
      {:gender, :string, [{"gender", :wildcard}]},
      {:uuid, :string, [{"uuid", :match}]},
      {:start_time, :date, []},
      {:system_user, :string, []},
      {:analytes, :nested, [
        {:result, :multi_field, [{"result", :wildcard}]},
        {:condition, :string, [{"condition", :wildcard}]},
      ]},
    ]
  end

  def pii?(field) do
    Enum.member? sensitive_fields, binary_to_atom(field)
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

  def query(params, post_body) do
    conditions = process_conditions(params, [])
    conditions = process_conditions(post_body, conditions)

    query = and_conditions(conditions)
    order = process_order(params)

    group_by = params["group_by"] || post_body["group_by"]

    if group_by do
      results = query_with_group_by(query, group_by)
    else
      results = query_without_group_by(query, order)
    end

    Enum.map results, fn test_result -> Enum.into(test_result, %{}) end
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
    data = Dict.put data, :device_uuid, device.secret_key
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
    if is_list(group_by) do
      all_group_by = group_by

      # Handle the case when they send us:
      #
      #     ["field", ranges]
      #
      # instead of:
      #
      #     [["field", ranges]]
      case group_by do
        [name, range] when is_binary(name) and is_list(range) ->
          all_group_by = [all_group_by]
        _ -> :ok
      end
    else
      all_group_by = String.split(group_by, ",")
    end

    all_group_by = sort_group_by(all_group_by)

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

  # nested fields must appear last in the group by
  defp sort_group_by(fields) do
    group_nested_fields Enum.sort fields, fn(f1, f2) ->
      g1 = classify_group_by_field(f1)
      g2 = classify_group_by_field(f2)

      case g1 do
        {:nested, _, _} ->
          case g2 do
            {:nested, _, _} ->
              f1 < f2
            _ ->
              false
          end
        _ ->
          case g2 do
            {:nested, _, _} ->
              true
            _ ->
              f1 < f2
          end
      end
    end
  end

  defp group_nested_fields([]) do
    []
  end

  defp group_nested_fields([field | fields]) do
    group_nested_fields(classify_group_by_field(field), fields)
  end

  defp group_nested_fields({:nested, _nesting_field, {:flat, field_name}}, fields) do
    [{:nested, [{:nested, _nesting_field, {:flat, field_name}}] ++ find_all_in_searchable_fields(fields)}]
  end

  defp group_nested_fields(field, fields) do
    [field] ++ group_nested_fields(fields)
  end

  defp process_group_by_buckets(aggregations, all_group_by, results, result, doc_count) do
    count = aggregations["count"]
    if count do
      [first_group_by | other_group_by] = all_group_by

      case first_group_by do
        {:range, field, _ranges} ->
          process_bucket(other_group_by, results, result, count["buckets"], fn(bucket) -> {field, [normalize(bucket["from"]), normalize(bucket["to"])]} end)
        {:date, _interval, field} ->
          process_bucket(other_group_by, results, result, count["buckets"], fn(bucket) -> {field, bucket["key_as_string"]} end)
        {:flat, field_name} ->
          process_bucket(other_group_by, results, result, count["buckets"], fn(bucket) -> {field_name, bucket["key"]} end)
        {:nested, fields} ->
          process_group_by_buckets(count, fields, results, result, doc_count)
        {:nested, _nesting_field, {:flat, field_name}} ->
          process_bucket(other_group_by, results, result, count["buckets"], fn(bucket) -> {field_name, bucket["key"]} end)
        nil ->
          raise "Trying to group by a non searchable field"
      end
    else
      result = result ++ [count: doc_count]
      [result | results]
    end
  end

  defp process_bucket(other_group_by, results, result, buckets, mapping) do
    Enum.reduce buckets, results, fn(bucket, results) ->
      result = result ++ [mapping.(bucket)]
      process_group_by_buckets(bucket, other_group_by, results, result, bucket["doc_count"])
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

  defp classify_group_by_field([field_name]) do
    classify_group_by_field(field_name)
  end

  defp classify_group_by_field(field_name) do
    if is_list(field_name) do
      [name, ranges] = field_name
      {:range, name, ranges}
    else
      date_captures = match_date_regex(field_name)
      if date_captures do
        {interval, field} = date_captures
        {:date, interval, field}
      else
        find_in_searchable_fields(field_name)
      end
    end
  end

  defp find_all_in_searchable_fields([name |rest]) do
    [find_in_searchable_fields(name) | find_all_in_searchable_fields(rest)]
  end

  defp find_all_in_searchable_fields([]) do
    []
  end

  defp find_in_searchable_fields(name) do
    find_in_fields name, searchable_fields
  end

  defp find_in_fields(_name, []) do
    nil
  end

  defp find_in_fields(name, [{field_name, :nested, properties} | fields]) do
    found = find_in_fields(name, properties)
    if found do
      {:nested, field_name, found}
    else
      find_in_fields(name, fields)
    end
  end

  defp find_in_fields(name, [{field_name, _, _} | fields]) do
    if name == atom_to_binary(field_name) do
      {:flat, name}
    else
      find_in_fields(name, fields)
    end
  end

  defp process_group_by([]) do
    []
  end

  defp process_group_by([{:nested, [nested_field | rest]}]) do
    case nested_field do
      {:nested, nesting_field, {:flat, field_name}} ->
        [
          count: [
            nested: [path: nesting_field],
            aggs: [
              count: [
                terms: [field: "#{nesting_field}.#{field_name}"]
              ] ++ process_group_by(rest)
            ]
          ]
        ]
      _ ->
        raise "Trying to group by a non searchable field"
    end
  end

  defp process_group_by([group_by]) do
    case group_by do
      {:range, name, ranges} ->
        [count: [range: [field: name, ranges: convert_ranges_to_elastic_search(ranges)]]]
      {:date, interval, field} ->
        format = case interval do
                         "year"  -> "yyyy"
                         "month" -> "yyyy-MM"
                         "week"  -> "yyyy-'W'w"
                         "day"   -> "yyyy-MM-dd"
                       end
        [count: [date_histogram: [field: field, interval: interval, format: format]]]
      {:flat, field_name} ->
        [count: [terms: [field: field_name]]]
      {:nested, nesting_field, {:flat, field_name}} ->
        [
          aggs: [
            count: [
              terms: [field: "#{nesting_field}.#{field_name}"]
            ]
          ]
        ]
      _ ->
        raise "Trying to group by a non searchable field"
    end
  end

  defp process_group_by([group_by|rest]) do
    rest_aggregations = process_group_by(rest)
    group_by_aggregations = process_group_by([group_by])

    [
      count: (group_by_aggregations[:count] ++ [aggregations: rest_aggregations])
    ]
  end

  defp convert_ranges_to_elastic_search([]) do
    []
  end

  defp convert_ranges_to_elastic_search([[from, to] | other]) do
    [[from: from, to: to] | convert_ranges_to_elastic_search(other)]
  end

  defp query_without_group_by(query, sort) do
    query = [
      search: [
        query: query,
        sort: sort,
      ],
      index: "#{Elasticsearch.index_prefix}*"
    ]
    result = Tirexs.Query.create_resource(query)
    Enum.map result.hits, fn(hit) -> hit["_source"] end
  end

  def field_matcher(field_name, :multi_field) do
    "#{field_name}.analyzed"
  end

  def field_matcher(field_name, _) do
    field_name
  end

  defp process_fields(fields, params, conditions) do
    Enum.reduce fields, conditions, fn field, conditions ->
      process_field(field, params, conditions)
    end
  end

  defp process_field({field_name, type, [{param_name, :wildcard}| tail ]}, params, conditions) do
    if field_value = params[param_name] do
      condition = if Regex.match? ~r/.*\*.*/, field_value do
        [wildcard: [{field_name, field_value}]]
      else
        [match: [{field_matcher(field_name, type), field_value}]]
      end
      conditions = [condition | conditions]
    end
    process_field({field_name, type, tail}, params, conditions)
  end

  defp process_field({field_name, type, [{param_name, :match}| tail ]}, params, conditions) do
    if field_value = params[param_name] do
      condition = [match: [{field_name, field_value}]]
      conditions = [condition | conditions]
    end
    process_field({field_name, type, tail}, params, conditions)
  end

  defp process_field({field_name, type, [{param_name, {:range, [start | options]}}| tail ]}, params, conditions) do
    if field_value = params[param_name] do
      condition = [range: [{field_name, [{start, field_value}] ++ options}]]
      conditions = [condition | conditions]
    end
    process_field({field_name, type, tail}, params, conditions)
  end

  defp process_field({field_name, :nested, nested_fields}, params, conditions) do
    nested_fields = Enum.map nested_fields, fn({name, type, properties}) ->
      {"#{field_name}.#{name}", type, properties}
    end
    nested_conditions = process_fields(nested_fields, params, [])
    case nested_conditions do
      [] ->
        conditions
      _  ->
        condition = [
          nested: [
            path: field_name,
            query: and_conditions(nested_conditions),
          ]
        ]
        [condition | conditions]
    end
  end

  defp process_field({_, _, []}, _, conditions) do
    conditions
  end

  defp process_conditions(params, conditions) do
    conditions = process_fields(searchable_fields, params, conditions)

    if Enum.empty?(conditions) do
      condition = [match_all: []]
      conditions = [condition | conditions]
    end

    conditions
  end

  defp and_conditions([condition]) do
    condition
  end

  defp and_conditions(conditions) do
    [bool: [must: conditions]]
  end

  defp process_order(params) do
    if order = params["order_by"] do
      all_orders = String.split(order, ",")
      Enum.map all_orders, fn(order) ->
        if String.starts_with?(order, "-") do
          {String.slice(order, 1, String.length(order) - 1), "desc"}
        else
          {order, "asc"}
        end
      end
    else
      [[created_at: "asc"]]
    end
  end

  defp normalize(value) when is_float(value) do
    truncated_value = trunc(value)
    if truncated_value == value do
      truncated_value
    else
      value
    end
  end

  defp normalize(value) do
    value
  end
end
