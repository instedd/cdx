defmodule FilterTest do
  use Cdp.TestCase
  import TestHelpers
  use Dynamo.HTTP.Case
  use Timex
  require Tirexs.Search

  test "checks for new tests since a date" do
    before_first_test = {{2010,1,1},{12,0,0}}
    before_first_test_formatted = format_date(before_first_test)

    create_result [result: "positive"], before_first_test

    response = get_one_update("", "{\"since\": \"#{before_first_test_formatted}\"}")
    assert HashDict.get(response, "result") == "positive"

    after_first_test = {{2010,1,2},{12,0,0}}

    create_result [result: "negative"], after_first_test

    response = get_one_update("", "{\"since\": \"#{format_date(after_first_test)}\"}")
    assert HashDict.get(response,"result") == "negative"

    [first, second] = get_updates("", "{\"since\": \"#{before_first_test_formatted}\"}")
    assert HashDict.get(first, "result") == "positive"
    assert HashDict.get(second, "result") == "negative"

    after_second_test = {{2010,1,3},{12,0,0}}
    after_second_test_formatted = format_date(after_second_test)

    assert_no_updates "", "{\"since\": \"#{after_second_test_formatted}\"}"
  end

  test "checks for new tests since a date with query string" do
    before_first_test = {{2010,1,1},{12,0,0}}
    before_first_test_formatted = escape_and_format(before_first_test)

    create_result [result: "positive"], before_first_test

    response = get_one_update("since=#{before_first_test_formatted}")
    assert HashDict.get(response, "result") == "positive"

    after_first_test = {{2010,1,2},{12,0,0}}

    create_result [result: "negative"], after_first_test

    response = get_one_update("since=#{escape_and_format(after_first_test)}")
    assert HashDict.get(response,"result") == "negative"

    [first, second] = get_updates("since=#{before_first_test_formatted}")
    assert HashDict.get(first, "result") == "positive"
    assert HashDict.get(second, "result") == "negative"

    assert_no_updates("since=#{escape_and_format({{2010,1,3},{12,0,0}})}")
  end

  test "checks for new tests util a date with query string" do
    create_result [result: "positive"], {{2010,1,1},{12,0,0}}

    after_first_test = escape_and_format({{2010,1,2},{12,0,0}})

    response = get_one_update("until=#{after_first_test}")
    assert HashDict.get(response, "result") == "positive"

    create_result [result: "negative"], {{2010,1,3},{12,0,0}}

    response = get_one_update("until=#{after_first_test}")
    assert HashDict.get(response,"result") == "positive"
  end

  test "filters by device", meta do
    post_result result: "positive"

    Repo.create Device.new(institution_id: meta[:institution].id, secret_key: "bar")

    post_result [result: "negative"], "bar"

    response = get_one_update("device=#{meta[:device].id}")
    assert HashDict.get(response, "result") == "positive"
  end

  test "filters by laboratory", meta do
    post_result result: "positive"

    create_device_and_laboratory(meta[:institution].id, "bar")

    post_result [result: "negative"], "bar"

    response = get_one_update("laboratory=#{meta[:laboratory1].id}")
    assert HashDict.get(response, "result") == "positive"
  end

  test "filters by institution", meta do
    post_result result: "positive"

    create_device_and_laboratory(meta[:institution2].id, "bar")

    post_result [result: "negative"], "bar"

    response = get_one_update("institution=#{meta[:institution].id}")
    assert HashDict.get(response, "result") == "positive"
  end

  test "filters by gender" do
    post_result result: "positive", gender: "male"
    post_result result: "negative", gender: "female"

    response = get_one_update("gender=male")
    assert HashDict.get(response, "result") == "positive"

    response = get_one_update("gender=female")
    assert HashDict.get(response, "result") == "negative"
  end

  test "filters by assay code" do
    post_result result: "positive", assay_name: "GX4001"
    post_result result: "negative", assay_name: "GX1234"

    response = get_one_update("assay_name=GX4001")
    assert HashDict.get(response, "result") == "positive"

    response = get_one_update("assay_name=GX1234")
    assert HashDict.get(response, "result") == "negative"
  end

  test "filters by age" do
    post_result result: "positive", age: 10
    post_result result: "negative", age: 20

    response = get_one_update("age=10")
    assert HashDict.get(response, "result") == "positive"

    response = get_one_update("age=20")
    assert HashDict.get(response, "result") == "negative"

    assert_no_updates("age=15")
  end

  test "filters by min age" do
    post_result result: "positive", age: 10
    post_result result: "negative", age: 20

    response = get_one_update("min_age=15")
    assert HashDict.get(response, "result") == "negative"

    response = get_one_update("min_age=20")
    assert HashDict.get(response, "result") == "negative"

    assert_no_updates("min_age=21")
  end

  test "filters by max age" do
    post_result result: "positive", age: 10
    post_result result: "negative", age: 20

    response = get_one_update("max_age=15")
    assert HashDict.get(response, "result") == "positive"

    response = get_one_update("max_age=10")
    assert HashDict.get(response, "result") == "positive"

    assert_no_updates("max_age=9")
  end

  test "filters by result" do
    post_result result: "positive", age: 10
    post_result result: "negative", age: 20

    response = get_one_update("result=positive")
    assert HashDict.get(response, "age") == 10
  end

  test "groups by gender" do
    post_result result: "positive", gender: "male"
    post_result result: "positive", gender: "male"
    post_result result: "negative", gender: "female"

    response = get_updates("group_by=gender")
    response = Enum.sort response, fn(r1, r2) -> r1["gender"] < r2["gender"] end

    assert_all_values response, ["gender", "count"], [
      ["female", 1],
      ["male", 2],
    ]
  end

  test "filters by uuid" do
    post_result result: "positive", assay_name: "GX4001"
    post_result result: "negative", assay_name: "GX1234"

    response = get_one_update("assay_name=GX4001")
    response = get_one_update("uuid=#{HashDict.get(response, "uuid")}")
    assert HashDict.get(response, "result") == "positive"

    response = get_one_update("assay_name=GX1234")
    response = get_one_update("uuid=#{HashDict.get(response, "uuid")}")
    assert HashDict.get(response, "result") == "negative"
  end
end
