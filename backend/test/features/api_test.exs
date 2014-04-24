defmodule ApiTest do
  use Timex
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  setup do
    institution = Cdp.Repo.create Cdp.Institution.new(name: "baz")
    institution2 = Cdp.Repo.create Cdp.Institution.new(name: "baz2")
    laboratory = Cdp.Repo.create Cdp.Laboratory.new(institution_id: institution.id, name: "bar")
    device = Cdp.Repo.create Cdp.Device.new(laboratory_id: laboratory.id, secret_key: "foo")
    settings = Tirexs.ElasticSearch.Config.new()
    index_name = Cdp.Institution.elasticsearch_index_name(institution.id)
    index_name2 = Cdp.Institution.elasticsearch_index_name(institution2.id)
    {:ok, institution: institution, institution2: institution2, laboratory: laboratory, device: device, settings: settings, index_name: index_name, index_name2: index_name2}
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

  test "checks for new tests since a date" do
    before_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    post_result result: "positive"

    response = get_one_update("", "{\"since\": \"#{before_first_test}\"}")
    assert HashDict.get(response, "result") == "positive"

    :timer.sleep(1000)
    after_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    post_result result: "negative"

    response = get_one_update("", "{\"since\": \"#{after_first_test}\"}")
    assert HashDict.get(response,"result") == "negative"

    [first, second] = get_updates("", "{\"since\": \"#{before_first_test}\"}")
    assert HashDict.get(first, "result") == "positive"
    assert HashDict.get(second, "result") == "negative"

    :timer.sleep(1000)
    after_second_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    assert_no_updates "", "{\"since\": \"#{after_second_test}\"}"
  end

  test "checks for new tests since a date with query string" do
    before_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    post_result result: "positive"

    response = get_one_update("since=#{Cdp.Cgi.escape(before_first_test)}")
    assert HashDict.get(response, "result") == "positive"

    :timer.sleep(1000)
    after_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    post_result result: "negative"

    response = get_one_update("since=#{Cdp.Cgi.escape(after_first_test)}")
    assert HashDict.get(response,"result") == "negative"

    [first, second] = get_updates("since=#{Cdp.Cgi.escape(before_first_test)}")
    assert HashDict.get(first, "result") == "positive"
    assert HashDict.get(second, "result") == "negative"

    :timer.sleep(1000)
    after_second_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    assert_no_updates("since=#{Cdp.Cgi.escape(after_second_test)}")
  end

  test "checks for new tests util a date with query string" do
    post_result result: "positive"

    after_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    response = get_one_update("until=#{Cdp.Cgi.escape(after_first_test)}")
    assert HashDict.get(response, "result") == "positive"

    :timer.sleep(1000)

    post_result result: "negative"

    response = get_one_update("until=#{Cdp.Cgi.escape(after_first_test)}")
    assert HashDict.get(response,"result") == "positive"
  end

  test "filters by device", meta do
    post_result result: "positive"

    Cdp.Repo.create Cdp.Device.new(laboratory_id: meta[:laboratory].id, secret_key: "bar")

    post_result [result: "negative"], "bar"

    response = get_one_update("device=#{meta[:device].id}")
    assert HashDict.get(response, "result") == "positive"
  end

  test "filters by laboratory", meta do
    post_result result: "positive"

    laboratory2 = Cdp.Repo.create Cdp.Laboratory.new(institution_id: meta[:institution].id, name: "baz")
    Cdp.Repo.create Cdp.Device.new(laboratory_id: laboratory2.id, secret_key: "bar")

    post_result [result: "negative"], "bar"

    response = get_one_update("laboratory=#{meta[:laboratory].id}")
    assert HashDict.get(response, "result") == "positive"
  end

  test "filters by institution", meta do
    post_result result: "positive"

    laboratory2 = Cdp.Repo.create Cdp.Laboratory.new(institution_id: meta[:institution2].id, name: "baz")
    Cdp.Repo.create Cdp.Device.new(laboratory_id: laboratory2.id, secret_key: "bar")

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

  teardown(meta) do
    Enum.each [Cdp.Institution, Cdp.Laboratory, Cdp.Device, Cdp.TestResult], &Cdp.Repo.delete_all/1
    Tirexs.ElasticSearch.delete meta[:index_name], meta[:settings]
    Tirexs.ElasticSearch.delete meta[:index_name2], meta[:settings]
  end
end
