defmodule PiiTest do
  use Cdp.TestCase
  import TestHelpers
  use Dynamo.HTTP.Case

  test "retrieves a test result PII by uuid" do
    create_result [result: "positive", patient_name: "jdoe"]

    result = get_one_update ""
    test_uuid = Dict.get(result, "uuid")

    response = get_pii(test_uuid)

    assert Dict.get(Dict.get(response, "pii"), "patient_name") == "jdoe"
    assert Dict.get(response, "uuid") == test_uuid
    assert Dict.get(response, "result") == nil
  end

  test "update a test result PII" do
    create_result [result: "positive", patient_name: "jdoe"]

    test_uuid = Dict.get(get_one_update(""), "uuid")

    put("/api/results/#{test_uuid}/pii", JSEX.encode!([patient_id: 2, patient_name: "foobar", patient_telephone_number: "1234", patient_zip_code: "ABC1234"]))

    updated_result = get_pii(test_uuid)
    pii = Dict.get(updated_result, "pii")
    assert Dict.get(pii, "patient_id") == 2
    assert Dict.get(pii, "patient_name") == "foobar"
    assert Dict.get(pii, "patient_telephone_number") == "1234"
    assert Dict.get(pii, "patient_zip_code") == "ABC1234"
    assert Dict.get(updated_result, "uuid") == test_uuid
    assert Dict.get(updated_result, "result") == nil
  end
end
