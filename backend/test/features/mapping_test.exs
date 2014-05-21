defmodule MappingTest do
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  import TestHelpers
  import Ecto.Query

  test "applies an existing manifest", context do
    device_model = Repo.insert DeviceModel.new(name: "fobar")
    device = Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "bar", device_model_id: device_model.id)

    manifest = Repo.insert Manifest.new(definition: """
                    { "field_mapping" : [{
                        "target_field": "assay_name",
                        "selector" : "assay/name",
                        "type" : "core"
                    }]}
                    """, version: 1)
    Repo.insert DeviceModelsManifests.new(device_model_id: device_model.id, manifest_id: manifest.id)

    post("/api/devices/bar/results", JSEX.encode!(%{"assay" => %{"name" => "GX4002"}, "patient_id" => 1234}))

    [result] = get_all_elasticsearch_results()
    assert result["_source"]["assay_name"] == "GX4002"
    assert result["_source"]["created_at"] != nil
    assert result["_source"]["patient_id"] == nil
  end

  test "stores pii according to manifest", context do
    device_model = Repo.insert DeviceModel.new(name: "fobar")
    device = Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "bar", device_model_id: device_model.id)

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

    post("/api/devices/bar/results", JSEX.encode!(%{"assay" => %{"name" => "GX4002"}, "patient_id" => 1234}))

    [result] = get_all_elasticsearch_results()
    assert result["_source"]["foo"] == nil

    test_uuid = result["_source"]["uuid"]

    updated_result = get_pii(test_uuid)
    pii = updated_result["pii"]
    assert pii["patient_id"] == nil
    assert pii["foo"] == 1234
  end

  test "Uses the last version of the manifest", context do
   device_model = Repo.insert DeviceModel.new(name: "fobar")
    device = Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "bar", device_model_id: device_model.id)

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

    post("/api/devices/bar/results", JSEX.encode!(%{"assay" => %{"name" => "GX4002"}, "patient_id" => 1234}))

    [result] = get_all_elasticsearch_results()
    assert result["_source"]["foo"] == nil
    assert result["_source"]["assay_name"] == "GX4002"
  end
end
