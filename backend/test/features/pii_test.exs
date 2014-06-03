defmodule PiiTest do
  use Cdp.TestCase
  import TestHelpers
  use Dynamo.HTTP.Case

  test "retrieves an event PII by uuid" do
    create_event [results: [result: "positive"], patient_name: "jdoe"]

    event_uuid = get_one_update("")["uuid"]

    response = get_pii(event_uuid)

    assert response["pii"]["patient_name"] == "jdoe"
    assert response["uuid"] == event_uuid
    assert response["results"] == nil
  end

  test "update an event PII" do
    create_event [results: [result: "positive"], patient_name: "jdoe"]

    event_uuid = get_one_update("")["uuid"]

    put("/api/events/#{event_uuid}/pii", JSEX.encode!([patient_id: 2, patient_name: "foobar", patient_telephone_number: "1234", patient_zip_code: "ABC1234"]))

    updated_event = get_pii(event_uuid)
    pii = updated_event["pii"]
    assert pii["patient_id"] == 2
    assert pii["patient_name"] == "foobar"
    assert pii["patient_telephone_number"] == "1234"
    assert pii["patient_zip_code"] == "ABC1234"
    assert updated_event["uuid"] == event_uuid
    assert updated_event["results"] == nil
  end
end
