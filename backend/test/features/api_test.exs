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

  def escape(string) do
    Cgi.escape(string)
  end

  def escape_and_format(date) do
    escape(format_date(date))
  end

  def create_device(institution_id, secret_key) do
    laboratory = Repo.create Laboratory.new(institution_id: institution_id, name: "baz")
    device = Repo.create Device.new(institution_id: institution_id, secret_key: secret_key)
    Repo.create DevicesLaboratories.new(laboratory_id: laboratory.id, device_id: device.id)
  end

  def fetch_many(dict, []) do
    []
  end

  def fetch_many(dict, [key|other_keys]) do
    [HashDict.get(dict, key) | fetch_many(dict, other_keys)]
  end

  def assert_values(dict, keys, values) do
    assert fetch_many(dict, keys) == values
  end

  def assert_all_values([], _keys, []) do
    # Ok
  end

  def assert_all_values([dict|other_dicts], keys, [values|other_values]) do
    assert_values dict, keys, values
    assert_all_values other_dicts, keys, other_values
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
    response = Enum.sort response, fn(r1, r2) -> r1["gender"] < r2["gender"] end

    assert_all_values response, ["gender", "count"], [
      ["female", 1],
      ["male", 2],
    ]
  end

  test "groups by gender and assay_code" do
    post_result result: "positive", gender: "male", assay_code: "a"
    post_result result: "positive", gender: "male", assay_code: "a"
    post_result result: "positive", gender: "male", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "a"
    post_result result: "negative", gender: "female", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "b"

    response = get_updates("group_by=gender,assay_code")
    response = Enum.sort response, fn(r1, r2) ->
      if r1["gender"] == r2["gender"] do
        r1["assay_code"] < r2["assay_code"]
      else
        r1["gender"] < r2["gender"]
      end
    end

    assert_all_values response, ["gender", "assay_code", "count"], [
      ["female", "a", 1],
      ["female", "b", 2],
      ["male", "a", 2],
      ["male", "b", 1],
    ]
  end

  test "groups by gender, result and assay_code" do
    post_result result: "positive", gender: "male", assay_code: "a"
    post_result result: "negative", gender: "male", assay_code: "a"
    post_result result: "positive", gender: "male", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "a"
    post_result result: "negative", gender: "female", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "b"

    response = get_updates("group_by=gender,result,assay_code")
    response = Enum.sort response, fn(r1, r2) ->
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

    assert_all_values response, ["gender", "result", "assay_code", "count"], [
      ["female", "negative", "a", 1],
      ["female", "negative", "b", 2],
      ["male", "negative", "a", 1],
      ["male", "positive", "a", 1],
      ["male", "positive", "b", 1],
    ]
  end

  test "group by year(date)" do
    create_result [result: "positive"], {{2010,1,1},{12,0,0}}
    create_result [result: "positive"], {{2010,1,2},{12,0,0}}
    create_result [result: "positive"], {{2011,1,1},{12,0,0}}

    response = get_updates("group_by=#{escape("year(created_at)")}")
    response = Enum.sort response, fn(r1, r2) -> r1["created_at"] < r2["created_at"] end

    assert_all_values response, ["created_at", "count"], [
      ["2010", 2],
      ["2011", 1],
    ]
  end

  test "group by month(date)" do
    create_result [result: "positive"], {{2010,1,1},{12,0,0}}
    create_result [result: "positive"], {{2010,2,2},{12,0,0}}
    create_result [result: "positive"], {{2011,1,1},{12,0,0}}
    create_result [result: "positive"], {{2011,1,2},{12,0,0}}
    create_result [result: "positive"], {{2011,2,1},{12,0,0}}

    response = get_updates("group_by=#{escape("month(created_at)")}")
    response = Enum.sort response, fn(r1, r2) -> r1["created_at"] < r2["created_at"] end

    assert_all_values response, ["created_at", "count"], [
      ["2010-01", 1],
      ["2010-02", 1],
      ["2011-01", 2],
      ["2011-02", 1],
      ]
  end

  test "group by week(date)" do
    create_result [result: "positive"], {{2010,1,4},{12,0,0}}
    create_result [result: "positive"], {{2010,1,5},{12,0,0}}
    create_result [result: "positive"], {{2010,1,6},{12,0,0}}
    create_result [result: "positive"], {{2010,1,12},{12,0,0}}
    create_result [result: "positive"], {{2010,1,13},{12,0,0}}

    response = get_updates("group_by=#{escape("week(created_at)")}")
    response = Enum.sort response, fn(r1, r2) -> r1["created_at"] < r2["created_at"] end

    assert_all_values response, ["created_at", "count"], [
      ["2010-W1", 3],
      ["2010-W2", 2],
      ]
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
