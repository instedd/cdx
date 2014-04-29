defmodule ApiTest do
  use Timex
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  setup do
    institution = Repo.create Institution.new(name: "baz")
    institution2 = Repo.create Institution.new(name: "baz2")
    laboratory = Repo.create Laboratory.new(institution_id: institution.id, name: "bar")
    device = Repo.create Device.new(institution_id: institution.id, secret_key: "foo")
    Repo.create DevicesLaboratories.new(laboratory_id: laboratory.id, device_id: device.id)
    {:ok, institution: institution, institution2: institution2, laboratory: laboratory, device: device}
  end

  def get_updates(query_string, post_data \\ "") do
    conn = get("/api/events?#{query_string}", post_data)
    assert conn.status == 200
    JSON.decode!(conn.sent_body)
  end

  def get_one_update(query_string, post_data \\ "") do
    [result] = get_updates(query_string, post_data)
    result
  end

  def assert_no_updates(query_string, post_data \\ "") do
    assert get_updates(query_string, post_data) == []
  end

  def post_result(result, device \\ "foo") do
    post("/devices/#{device}", JSON.encode!(result))
  end

  def create_result(result, date \\ :calendar.universal_time(), device \\ "foo") do
    TestResult.create_and_enqueue(device, JSON.encode!(result), date)
  end

  def format_date(date) do
    DateFormat.format!(Date.from(date), "{ISO}")
  end

  def escape_and_format(date) do
    Cgi.escape(format_date(date))
  end

  def create_device(institution_id, secret_key) do
    laboratory = Repo.create Laboratory.new(institution_id: institution_id, name: "baz")
    device = Repo.create Device.new(institution_id: institution_id, secret_key: secret_key)
    Repo.create DevicesLaboratories.new(laboratory_id: laboratory.id, device_id: device.id)
  end


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

    create_device(meta[:institution].id, "bar")

    post_result [result: "negative"], "bar"

    response = get_one_update("laboratory=#{meta[:laboratory].id}")
    assert HashDict.get(response, "result") == "positive"
  end

  test "filters by institution", meta do
    post_result result: "positive"

    create_device(meta[:institution2].id, "bar")

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
    [female, male] = Enum.sort response, fn(r1, r2) -> r1["gender"] < r2["gender"] end

    assert HashDict.get(female, "count") == 1
    assert HashDict.get(female, "gender") == "female"

    assert HashDict.get(male, "count") == 2
    assert HashDict.get(male, "gender") == "male"
  end

  test "groups by gender and assay_code" do
    post_result result: "positive", gender: "male", assay_code: "a"
    post_result result: "positive", gender: "male", assay_code: "a"
    post_result result: "positive", gender: "male", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "a"
    post_result result: "negative", gender: "female", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "b"

    response = get_updates("group_by=gender,assay_code")
    [female_a, female_b, male_a, male_b] = Enum.sort response, fn(r1, r2) ->
      if r1["gender"] == r2["gender"] do
        r1["assay_code"] < r2["assay_code"]
      else
        r1["gender"] < r2["gender"]
      end
    end

    assert HashDict.get(female_a, "count") == 1
    assert HashDict.get(female_a, "gender") == "female"
    assert HashDict.get(female_a, "assay_code") == "a"

    assert HashDict.get(female_b, "count") == 2
    assert HashDict.get(female_b, "gender") == "female"
    assert HashDict.get(female_b, "assay_code") == "b"

    assert HashDict.get(male_a, "count") == 2
    assert HashDict.get(male_a, "gender") == "male"
    assert HashDict.get(male_a, "assay_code") == "a"

    assert HashDict.get(male_b, "count") == 1
    assert HashDict.get(male_b, "gender") == "male"
    assert HashDict.get(male_b, "assay_code") == "b"
  end

  test "groups by gender, result and assay_code" do
    post_result result: "positive", gender: "male", assay_code: "a"
    post_result result: "negative", gender: "male", assay_code: "a"
    post_result result: "positive", gender: "male", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "a"
    post_result result: "negative", gender: "female", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "b"

    response = get_updates("group_by=gender,result,assay_code")
    [female_negative_a, female_negative_b, male_negative_a, male_positive_a, male_positive_b] =
      Enum.sort response, fn(r1, r2) ->
        if r1["gender"] == r2["gender"] do
          if r1["result"] == r2["result"] do
            r1["assay_code"] < r2["assay_code"]
          else
            r1["result"] < r2["result"]
          end
        else
          r1["gender"] < r2["gender"]
        end
      end

    assert HashDict.get(female_negative_a, "count") == 1
    assert HashDict.get(female_negative_a, "gender") == "female"
    assert HashDict.get(female_negative_a, "result") == "negative"
    assert HashDict.get(female_negative_a, "assay_code") == "a"

    assert HashDict.get(female_negative_b, "count") == 2
    assert HashDict.get(female_negative_b, "gender") == "female"
    assert HashDict.get(female_negative_b, "result") == "negative"
    assert HashDict.get(female_negative_b, "assay_code") == "b"

    assert HashDict.get(male_negative_a, "count") == 1
    assert HashDict.get(male_negative_a, "gender") == "male"
    assert HashDict.get(male_negative_a, "result") == "negative"
    assert HashDict.get(male_negative_a, "assay_code") == "a"

    assert HashDict.get(male_positive_a, "count") == 1
    assert HashDict.get(male_positive_a, "gender") == "male"
    assert HashDict.get(male_positive_a, "result") == "positive"
    assert HashDict.get(male_positive_a, "assay_code") == "a"

    assert HashDict.get(male_positive_b, "count") == 1
    assert HashDict.get(male_positive_b, "gender") == "male"
    assert HashDict.get(male_positive_b, "result") == "positive"
    assert HashDict.get(male_positive_b, "assay_code") == "b"
  end

  teardown(meta) do
    Enum.each [Institution, Laboratory, Device, TestResult], &Repo.delete_all/1
    settings = Tirexs.ElasticSearch.Config.new()
    delete_index meta[:institution], settings
    delete_index meta[:institution2], settings
  end

  def delete_index(institution, settings) do
    Tirexs.ElasticSearch.delete Institution.elasticsearch_index_name(institution.id), settings
  end
end
