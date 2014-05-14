defmodule FilterTest do
  use Cdp.TestCase
  import TestHelpers
  require Tirexs.Search

  test "checks for new tests since a date" do
    before_first_test = {{2010,1,1},{12,0,0}}
    before_first_test_formatted = format_date(before_first_test)

    create_result [analytes: [result: "positive"]], before_first_test

    response = get_one_update("", "{\"since\": \"#{before_first_test_formatted}\"}")
    assert response["analytes"]["result"] == "positive"

    after_first_test = {{2010,1,2},{12,0,0}}

    create_result [analytes: [result: "negative"]], after_first_test

    response = get_one_update("", "{\"since\": \"#{format_date(after_first_test)}\"}")
    assert response["analytes"]["result"] == "negative"

    [first, second] = get_updates("", "{\"since\": \"#{before_first_test_formatted}\"}")
    assert first["analytes"]["result"] == "positive"
    assert second["analytes"]["result"] == "negative"

    after_second_test = {{2010,1,3},{12,0,0}}
    after_second_test_formatted = format_date(after_second_test)

    assert_no_updates "", "{\"since\": \"#{after_second_test_formatted}\"}"
  end

  test "checks for new tests since a date with query string" do
    before_first_test = {{2010,1,1},{12,0,0}}
    before_first_test_formatted = escape_and_format(before_first_test)

    create_result [analytes: [result: "positive"]], before_first_test

    response = get_one_update("since=#{before_first_test_formatted}")
    assert response["analytes"]["result"] == "positive"

    after_first_test = {{2010,1,2},{12,0,0}}

    create_result [analytes: [result: "negative"]], after_first_test

    response = get_one_update("since=#{escape_and_format(after_first_test)}")
    assert response["analytes"]["result"] == "negative"

    [first, second] = get_updates("since=#{before_first_test_formatted}")
    assert first["analytes"]["result"] == "positive"
    assert second["analytes"]["result"] == "negative"

    assert_no_updates("since=#{escape_and_format({{2010,1,3},{12,0,0}})}")
  end

  test "checks for new tests util a date with query string" do
    create_result [analytes: [result: "positive"]], {{2010,1,1},{12,0,0}}

    after_first_test = escape_and_format({{2010,1,2},{12,0,0}})

    response = get_one_update("until=#{after_first_test}")
    assert response["analytes"]["result"] == "positive"

    create_result [analytes: [result: "negative"]], {{2010,1,3},{12,0,0}}

    response = get_one_update("until=#{after_first_test}")
    assert response["analytes"]["result"] == "positive"
  end

  test "filters by device", context do
    post_result analytes: [result: "positive"]

    Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "bar")

    post_result [analytes: [result: "negative"]], "bar"

    response = get_one_update("device=foo")
    assert response["analytes"]["result"] == "positive"
  end

  test "filters by laboratory", context do
    post_result analytes: [result: "positive"]

    create_device_and_laboratory(context[:institution].id, "bar")

    post_result [analytes: [result: "negative"]], "bar"

    response = get_one_update("laboratory=#{context[:laboratory1].id}")
    assert response["analytes"]["result"] == "positive"
  end

  test "filters by institution", context do
    post_result analytes: [result: "positive"]

    create_device_and_laboratory(context[:institution2].id, "bar")

    post_result [analytes: [result: "negative"]], "bar"

    response = get_one_update("institution=#{context[:institution].id}")
    assert response["analytes"]["result"] == "positive"
  end

  test "filters by gender" do
    post_result analytes: [result: "positive"], gender: "male"
    post_result analytes: [result: "negative"], gender: "female"

    response = get_one_update("gender=male")
    assert response["analytes"]["result"] == "positive"

    response = get_one_update("gender=female")
    assert response["analytes"]["result"] == "negative"
  end

  test "filters by assay name" do
    post_result analytes: [result: "positive"], assay_name: "GX4001"
    post_result analytes: [result: "negative"], assay_name: "GX1234"

    response = get_one_update("assay_name=GX4001")
    assert response["analytes"]["result"] == "positive"

    response = get_one_update("assay_name=GX1234")
    assert response["analytes"]["result"] == "negative"
  end

  test "filters by age" do
    post_result analytes: [result: "positive"], age: 10
    post_result analytes: [result: "negative"], age: 20

    response = get_one_update("age=10")
    assert response["analytes"]["result"] == "positive"

    response = get_one_update("age=20")
    assert response["analytes"]["result"] == "negative"

    assert_no_updates("age=15")
  end

  test "filters by min age" do
    post_result analytes: [result: "positive"], age: 10
    post_result analytes: [result: "negative"], age: 20

    response = get_one_update("min_age=15")
    assert response["analytes"]["result"] == "negative"

    response = get_one_update("min_age=20")
    assert response["analytes"]["result"] == "negative"

    assert_no_updates("min_age=21")
  end

  test "filters by max age" do
    post_result analytes: [result: "positive"], age: 10
    post_result analytes: [result: "negative"], age: 20

    response = get_one_update("max_age=15")
    assert response["analytes"]["result"] == "positive"

    response = get_one_update("max_age=10")
    assert response["analytes"]["result"] == "positive"

    assert_no_updates("max_age=9")
  end

  test "filters by result" do
    post_result analytes: [condition: "MTB", result: "positive"], age: 10
    post_result analytes: [condition: "MTB", result: "negative"], age: 20

    response = get_one_update("result=positive")
    assert response["age"] == 10
  end

  test "filters by uuid" do
    post_result analytes: [result: "positive"], assay_name: "GX4001"
    post_result analytes: [result: "negative"], assay_name: "GX1234"

    response = get_one_update("assay_name=GX4001")
    response = get_one_update("uuid=#{response["uuid"]}")
    assert response["analytes"]["result"] == "positive"

    response = get_one_update("assay_name=GX1234")
    response = get_one_update("uuid=#{response["uuid"]}")
    assert response["analytes"]["result"] == "negative"
  end

  test "filters by a partial match" do
    post_result analytes: [result: "positive"], assay_name: "GX4001"
    post_result analytes: [result: "negative"], assay_name: "GX1234"

    response = get_updates("assay_name=GX*")
    response = Enum.sort response, fn(r1, r2) -> r1["assay_name"] < r2["assay_name"] end
    assert_all_values response, ["analytes", "assay_name"], [
      [%{"result" => "negative"}, "GX1234"],
      [%{"result" => "positive"}, "GX4001"],
    ]
  end

  test "filters by condition name" do
    post_result analytes: [result: "positive", condition: "Flu"]
    post_result analytes: [result: "negative", condition: "MTB"]

    response = get_one_update("condition=MTB")
    assert response["analytes"]["result"] == "negative"

    response = get_one_update("condition=Flu")
    assert response["analytes"]["result"] == "positive"
  end

  test "filters by an analyzed result" do
    post_result analytes: [result: "negative", condition: "MTB"]
    post_result analytes: [result: "Positive with RIFF resistance", condition: "MTB"]

    response = get_one_update("result=positive")
    assert response["analytes"]["result"] == "Positive with RIFF resistance"
  end

  test "filters by an result, age and condition" do
    post_result analytes: [result: "negative", condition: "MTB"], age: 20
    post_result analytes: [result: "positive", condition: "MTB"], age: 20
    post_result analytes: [result: "negative", condition: "Flu"], age: 20

    response = get_one_update("result=negative&age=20&condition=Flu")
    assert response["analytes"]["result"] == "negative"
  end

  test "filters by location", context do
    device = Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "bar")
    Repo.insert DevicesLaboratories.new(laboratory_id: context[:laboratory2].id, device_id: device.id)
    device = Repo.insert Device.new(institution_id: context[:institution].id, secret_key: "baz")
    Repo.insert DevicesLaboratories.new(laboratory_id: context[:laboratory3].id, device_id: device.id)

    post_result analytes: [result: "negative"]
    post_result [analytes: [result: "positive"]], "bar"
    post_result [analytes: [result: "positive with riff"]], "baz"

    response = get_one_update("location=#{context[:location1].id}")
    assert response["analytes"]["result"] == "negative"
    response = get_one_update("location=#{context[:location2].id}")
    assert response["analytes"]["result"] == "positive"
    response = get_updates("location=#{context[:parent_location].id}")
    response = Enum.sort response, fn(r1, r2) -> r1["location_id"] < r2["location_id"] end
    assert_all_values response, ["analytes", "location_id"], [
      [%{"result" => "negative"}, context[:location1].id],
      [%{"result" => "positive"}, context[:location2].id],
    ]
    response = get_updates("location=#{context[:root_location].id}")
    response = Enum.sort response, fn(r1, r2) -> r1["location_id"] < r2["location_id"] end
    assert_all_values response, ["analytes", "location_id"], [
      [%{"result" => "negative"}, context[:location1].id],
      [%{"result" => "positive"}, context[:location2].id],
      [%{"result" => "positive with riff"}, context[:location3].id],
    ]
  end
end
