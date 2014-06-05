defmodule ReportingTest do
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search
  import TestHelpers

  test "create event in postgres", context do
    conn = post("/api/devices/foo/events", context[:data])
    assert conn.status == 200

    [event] = Repo.all Event
    assert event.device_id == context[:device].id
    assert event.raw_data != context[:data]
    event = Event.decrypt(event)
    assert event.raw_data == context[:data]
  end

  test "create event in elasticsearch", context do
    post("/api/devices/foo/events", context[:data])

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["event"] == "positive"
    assert event["_source"]["created_at"] != nil
    assert event["_source"]["device_uuid"] == "foo"
  end

  test "doesn't store sensitive data in elasticsearch" do
    data = "{\"event\": \"positive\", \"patient_id\": 1234}"
    post("/api/devices/foo/events", data)

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["event"] == "positive"
    assert event["_source"]["created_at"] != nil
    assert event["_source"]["patient_id"] == nil
  end

  test "store the location id when the device is registered in only one laboratory", context do
    post("/api/devices/foo/events", context[:data])

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["location_id"] == context[:location1].id
    assert event["_source"]["laboratory_id"] == context[:laboratory1].id
    assert Enum.sort(event["_source"]["parent_locations"]) == Enum.sort([context[:location1].id, context[:parent_location].id, context[:root_location].id])
  end

  test "store the parent location id when the device is registered more than one laboratory", context do
    Repo.insert %DevicesLaboratories{laboratory_id: context[:laboratory2].id, device_id: context[:device].id}
    Repo.insert %DevicesLaboratories{laboratory_id: context[:laboratory3].id, device_id: context[:device].id}

    post("/api/devices/foo/events", context[:data])

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["location_id"] == context[:root_location].id
    assert event["_source"]["laboratory_id"] == nil
    assert Enum.sort(event["_source"]["parent_locations"]) == Enum.sort([context[:root_location].id])
  end


  test "store the parent location id when the device is registered more than one laboratory with another tree order", context do
    Repo.insert %DevicesLaboratories{laboratory_id: context[:laboratory3].id, device_id: context[:device].id}
    Repo.insert %DevicesLaboratories{laboratory_id: context[:laboratory2].id, device_id: context[:device].id}

    post("/api/devices/foo/events", context[:data])

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["location_id"] == context[:root_location].id
    assert event["_source"]["laboratory_id"] == nil
    assert Enum.sort(event["_source"]["parent_locations"]) == Enum.sort([context[:root_location].id])
  end

  test "store nil if no location was found", context do
    Repo.insert %Device{institution_id: context[:institution].id, secret_key: "bar"}

    post("/api/devices/bar/events", context[:data])

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["location_id"] == nil
    assert event["_source"]["laboratory_id"] == nil
    assert event["_source"]["parent_locations"] == []
  end

  test "overrides event if event_id is the same" do
    data = JSEX.encode! [event_id: "1234", age: 20]
    post("/api/devices/foo/events", data)

    [event] = Repo.all Event
    assert event.event_id == "1234"

    data = JSEX.encode! [event_id: "1234", age: 30]
    post("/api/devices/foo/events", data)

    [event] = Repo.all Event
    event = Event.decrypt(event)
    raw_data = JSEX.decode! event.raw_data
    assert raw_data["age"] == 30

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["age"] == 30
  end
end
