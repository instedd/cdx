defmodule CustomFieldTest do
  use Cdp.TestCase
  import TestHelpers
  use Dynamo.HTTP.Case

  test "retrieves an event custom fields by uuid", context do
    device_model = Repo.insert %DeviceModel{name: "fobar"}
    device = Repo.insert %Device{institution_id: context[:institution].id, secret_key: "bar", device_model_id: device_model.id}

    manifest = Repo.insert %Manifest{definition: """
      { "field_mapping" : [
        {
          "target_field": "foo",
          "selector" : "some_field",
          "type" : "custom",
          "pii": false,
          "indexed": false
        }
      ]}
      """, version: 1}
    Repo.insert %DeviceModelsManifests{device_model_id: device_model.id, manifest_id: manifest.id}

    post("/api/devices/bar/events", JSEX.encode!(%{"some_field" => 1234}))

    test_uuid = get_one_update("")["uuid"]

    response = get_custom_fields(test_uuid)

    assert response["custom_fields"]["foo"] == 1234
    assert response["uuid"] == test_uuid
  end
end
