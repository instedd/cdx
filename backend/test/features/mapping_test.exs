defmodule MappingTest do
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  import TestHelpers

  test "applies an existing manifest", context do
    device_model = Repo.insert DeviceModel.new(name: "fobar")
    Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "bar", device_model_id: device_model.id)

    manifest = Repo.insert Manifest.new(definition: """
      { "field_mapping" : [{
          "target_field": "assay_name",
          "selector" : "assay/name",
          "type" : "core"
      }]}
      """, version: 1)
    Repo.insert DeviceModelsManifests.new(device_model_id: device_model.id, manifest_id: manifest.id)

    post("/api/devices/bar/events", JSEX.encode!(%{"assay" => %{"name" => "GX4002"}, "patient_id" => 1234}))

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["assay_name"] == "GX4002"
    assert event["_source"]["created_at"] != nil
    assert event["_source"]["patient_id"] == nil
  end

  test "stores pii according to manifest", context do
    device_model = Repo.insert DeviceModel.new(name: "fobar")
    Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "bar", device_model_id: device_model.id)

    manifest = Repo.insert Manifest.new(definition: """
      { "field_mapping" : [
        {
          "target_field": "assay_name",
          "selector" : "assay/name",
          "type" : "core"
        },
        {
          "target_field": "foo",
          "selector" : "patient_id",
          "type" : "custom",
          "pii": true
        }
      ]}
      """, version: 1)
    Repo.insert DeviceModelsManifests.new(device_model_id: device_model.id, manifest_id: manifest.id)

    post("/api/devices/bar/events", JSEX.encode!(%{"assay" => %{"name" => "GX4002"}, "patient_id" => 1234}))

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["foo"] == nil

    test_uuid = event["_source"]["uuid"]

    event = get_pii(test_uuid)
    pii = event["pii"]
    assert pii["patient_id"] == nil
    assert pii["foo"] == 1234
  end

  test "Uses the last version of the manifest", context do
    device_model = Repo.insert DeviceModel.new(name: "fobar")
    Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "bar", device_model_id: device_model.id)

    manifest = Repo.insert Manifest.new(definition: """
      { "field_mapping" : [{
          "target_field": "assay_name",
          "selector" : "assay/name",
          "type" : "core"
      }]}
      """, version: 2)
    Repo.insert DeviceModelsManifests.new(device_model_id: device_model.id, manifest_id: manifest.id)

    manifest = Repo.insert Manifest.new(definition: """
      { "field_mapping" : [{
          "target_field": "foo",
          "selector" : "assay/name",
          "type" : "core"
      }]}
      """, version: 1)

    Repo.insert DeviceModelsManifests.new(device_model_id: device_model.id, manifest_id: manifest.id)

    post("/api/devices/bar/events", JSEX.encode!(%{"assay" => %{"name" => "GX4002"}, "patient_id" => 1234}))

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["foo"] == nil
    assert event["_source"]["assay_name"] == "GX4002"
  end

  test "stores custom fields according to the manifest", context do
    device_model = Repo.insert DeviceModel.new(name: "fobar")
    Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "bar", device_model_id: device_model.id)

    manifest = Repo.insert Manifest.new(definition: """
      { "field_mapping" : [
        {
          "target_field": "foo",
          "selector" : "some_field",
          "type" : "custom",
          "pii": false,
          "indexed": false
        }
      ]}
      """, version: 1)
    Repo.insert DeviceModelsManifests.new(device_model_id: device_model.id, manifest_id: manifest.id)

    post("/api/devices/bar/events", JSEX.encode!(%{"some_field" => 1234}))

    [event] = get_all_elasticsearch_events()
    assert event["_source"]["foo"] == nil

    test_uuid = event["_source"]["uuid"]

    event = get_pii(test_uuid)
    pii = event["pii"]
    assert pii["some_field"] == nil
    assert pii["foo"] == nil

    [event] = Repo.all Event
    assert JSEX.decode!(event.custom_fields)["foo"] == 1234
  end
end
