defmodule TestResultCreation do
  use Timex
  import Tirexs.Bulk

  def update_pii(result_uuid, data, date \\ :calendar.universal_time()) do
    date = Ecto.DateTime.from_erl(date)

    sensitive_data = Enum.map TestResult.sensitive_fields, fn field_name ->
      {field_name, data[atom_to_binary(field_name)]}
    end

    test_result = TestResult.find_by_uuid_in_postgres(result_uuid)
    test_result = test_result.sensitive_data sensitive_data
    test_result = test_result.updated_at date
    test_result = TestResult.encrypt(test_result)

    Repo.update(test_result)
  end

  def create(device_key, raw_data, date \\ :calendar.universal_time()) do
    device = Device.find_by_key(device_key)

    {:ok, data} = JSEX.decode raw_data

    uuid = :erlang.iolist_to_binary(:uuid.to_string(:uuid.uuid1()))
    create_in_db(device, data, raw_data, date, uuid)
    create_in_elasticsearch(device, data, date, uuid)
  end

  defp create_in_db(device, data, raw_data, date, uuid) do
    date = Ecto.DateTime.from_erl(date)

    sensitive_data = Enum.map TestResult.sensitive_fields, fn field_name ->
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

    test_result = TestResult.encrypt(test_result)
    Repo.insert(test_result)
  end

  defp create_in_elasticsearch(device, data, date, uuid) do
    institution_id = device.institution_id

    data = Dict.drop(data, (Enum.map TestResult.sensitive_fields, &atom_to_binary(&1)))

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
end
