defmodule EventCreation do
  use Timex
  import Tirexs.Bulk
  import Ecto.Query

  def update_pii(uuid, data, date \\ :calendar.universal_time()) do
    date = Ecto.DateTime.from_erl(date)

    sensitive_data = Enum.map Event.sensitive_fields, fn field_name ->
      {field_name, data[atom_to_binary(field_name)]}
    end

    event = Event.find_by_uuid_in_postgres(uuid)
    event = event.sensitive_data sensitive_data
    event = event.updated_at date
    event = Event.encrypt(event)

    Repo.update(event)
  end

  def create(device_key, raw_data, date \\ :calendar.universal_time()) do
    create(Device.find_by_key(device_key), raw_data, JSEX.decode!(raw_data), date, :erlang.iolist_to_binary(:uuid.to_string(:uuid.uuid1())))
  end

  def create({device, [], laboratories}, raw_data, data, date, uuid) do
    # TODO: when no manifest is found we should use a default mapping
    event_id = data[:event_id]

    sensitive_data = Enum.map Event.sensitive_fields, fn field_name ->
      {field_name, data[field_name]}
    end
    create_in_db(device, sensitive_data, [], raw_data, date, uuid, event_id)

    data = Dict.drop(data, (Enum.map Event.sensitive_fields, &atom_to_binary(&1)))

    create_in_elasticsearch(device, laboratories, data, date, uuid, event_id)
  end

  def create({device, [manifest], laboratories}, raw_data, data, date, uuid) do
    data = Manifest.apply(JSEX.decode!(manifest.definition), data)

    event_id = data[:event_id]

    create_in_db(device, data[:pii], data[:custom], raw_data, date, uuid, event_id)
    create_in_elasticsearch(device, laboratories, data[:indexed], date, uuid, event_id)
  end

  def create({device, [manifest| manifests], laboratories}, raw_data, data, date, uuid) do
    manifest = Enum.reduce manifests, manifest, fn(current_manifest, last_manifest) ->
      if last_manifest.version < current_manifest.version do
        current_manifest
      else
        last_manifest
      end
    end
    create({device, [manifest], laboratories}, raw_data, data, date, uuid)
  end

  def find_by_device_id_and_event_id(device_id, event_id) do
    query = from t in Event,
      where: t.device_id == ^device_id,
      where: t.event_id == ^event_id,
      select: t
    events = Repo.all(query)
    case events do
      [event] -> event
      _ -> nil
    end
  end

  defp create_in_db(device, sensitive_data, custom_data, raw_data, date, uuid, event_id) do
    date = Ecto.DateTime.from_erl(date)

    event = %Event{
      device_id: device.id,
      event_id: event_id,
      raw_data: raw_data,
      uuid: uuid,
      sensitive_data: sensitive_data,
      custom_fields: JSEX.encode!(custom_data),
      created_at: date,
      updated_at: date,
    }

    event = Event.encrypt(event)

    # Check if the event already exists with that event_id
    if event_id do
      existing_event = find_by_device_id_and_event_id(device.id, event_id)
      if existing_event do
        event = event.id(existing_event.id)
        Repo.update(event)
      else
        Repo.insert(event)
      end
    else
      Repo.insert(event)
    end
  end

  defp create_in_elasticsearch(device, [], data, date, uuid, event_id) do
    create_in_elasticsearch(device, nil, [], nil, date, data, uuid, event_id)
  end

  defp create_in_elasticsearch(device, [laboratory], data, date, uuid, event_id) do
    laboratory_id = laboratory.id
    location_id = laboratory.location_id
    parent_locations = Location.with_parents Repo.get(Location, laboratory.location_id)
    create_in_elasticsearch(device, laboratory_id, parent_locations, location_id, date, data, uuid, event_id)
  end

  defp create_in_elasticsearch(device, laboratories, data, date, uuid, event_id) do
    locations = (Enum.map laboratories, fn laboratory -> Repo.get Location, laboratory.location_id end)
    root_location = Location.common_root(locations)
    parent_locations = Location.with_parents root_location
    if root_location do
      location_id = root_location.id
    end
    create_in_elasticsearch(device, nil, parent_locations, location_id, date, data, uuid, event_id)
  end

  defp create_in_elasticsearch(device, laboratory_id, parent_locations, location_id, date, data, uuid, event_id) do
    institution_id = device.institution_id

    data = Dict.put data, :type, "event"
    data = Dict.put data, :created_at, (DateFormat.format!(Date.from(date), "{ISO}"))
    data = Dict.put data, :device_uuid, device.secret_key
    data = Dict.put data, :location_id, location_id
    data = Dict.put data, :parent_locations, parent_locations
    data = Dict.put data, :laboratory_id, laboratory_id
    data = Dict.put data, :institution_id, institution_id
    data = Dict.put data, :uuid, uuid

    if event_id do
      data = Dict.put data, :id, "#{device.secret_key}_#{event_id}"
    end

    settings = Tirexs.ElasticSearch.Config.new()
    Tirexs.Bulk.store [index: Institution.elasticsearch_index_name(institution_id), refresh: true], settings do
      index data
    end
  end
end
