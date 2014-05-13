defmodule PiiTest do
  use Cdp.TestCase
  import TestHelpers
  use Dynamo.HTTP.Case

  test "retrieves a test result PII by uuid" do
    create_result [analytes: [result: "positive"], patient_name: "jdoe"]

    test_uuid = get_one_update("")["uuid"]

    response = get_pii(test_uuid)

    assert response["pii"]["patient_name"] == "jdoe"
    assert response["uuid"] == test_uuid
    assert response["analytes"] == nil
  end

  test "update a test result PII" do
    create_result [analytes: [result: "positive"], patient_name: "jdoe"]

    test_uuid = get_one_update("")["uuid"]

    put("/api/results/#{test_uuid}/pii", JSEX.encode!([patient_id: 2, patient_name: "foobar", patient_telephone_number: "1234", patient_zip_code: "ABC1234"]))

    updated_result = get_pii(test_uuid)
    pii = updated_result["pii"]
    assert pii["patient_id"] == 2
    assert pii["patient_name"] == "foobar"
    assert pii["patient_telephone_number"] == "1234"
    assert pii["patient_zip_code"] == "ABC1234"
    assert updated_result["uuid"] == test_uuid
    assert updated_result["analytes"] == nil
  end
end
