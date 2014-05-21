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
end
