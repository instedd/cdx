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

  test "checks for new tests since a date" do
    before_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    first_test = [result: "positive"]
    {:ok, first_test_json} = JSON.encode first_test
    post("/devices/foo", first_test_json)

    conn = get("/api/updates", "{\"since\": \"#{before_first_test}\"}")
    assert conn.status == 200
    {:ok, [response] } = JSON.decode(conn.sent_body)
    assert HashDict.get(response, "result") == "positive"

    :timer.sleep(1000)
    after_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    second_test = [result: "negative"]
    {:ok, second_test_json} = JSON.encode second_test
    post("/devices/foo", second_test_json)

    conn = get("/api/updates", "{\"since\": \"#{after_first_test}\"}")
    assert conn.status == 200
    {:ok, [response]} = JSON.decode(conn.sent_body)
    assert HashDict.get(response,"result") == "negative"

    conn = get("/api/updates", "{\"since\": \"#{before_first_test}\"}")
    assert conn.status == 200
    {:ok, [first, second]} = JSON.decode(conn.sent_body)
    assert HashDict.get(first, "result") == "positive"
    assert HashDict.get(second, "result") == "negative"

    :timer.sleep(1000)
    after_second_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    conn = get("/api/updates", "{\"since\": \"#{after_second_test}\"}")
    assert conn.status == 200
    {:ok, []} = JSON.decode(conn.sent_body)
  end

  test "checks for new tests since a date with query string" do
    before_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    first_test = [result: "positive"]
    {:ok, first_test_json} = JSON.encode first_test
    post("/devices/foo", first_test_json)

    conn = get("/api/updates?since=#{Cdp.Cgi.escape(before_first_test)}")
    assert conn.status == 200
    {:ok, [response] } = JSON.decode(conn.sent_body)
    assert HashDict.get(response, "result") == "positive"

    :timer.sleep(1000)
    after_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    second_test = [result: "negative"]
    {:ok, second_test_json} = JSON.encode second_test
    post("/devices/foo", second_test_json)

    conn = get("/api/updates?since=#{Cdp.Cgi.escape(after_first_test)}")
    assert conn.status == 200
    {:ok, [response]} = JSON.decode(conn.sent_body)
    assert HashDict.get(response,"result") == "negative"

    conn = get("/api/updates?since=#{Cdp.Cgi.escape(before_first_test)}")
    assert conn.status == 200
    {:ok, [first, second]} = JSON.decode(conn.sent_body)
    assert HashDict.get(first, "result") == "positive"
    assert HashDict.get(second, "result") == "negative"

    :timer.sleep(1000)
    after_second_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    conn = get("/api/updates?since=#{Cdp.Cgi.escape(after_second_test)}")
    assert conn.status == 200
    {:ok, []} = JSON.decode(conn.sent_body)
  end

  test "filters by device", meta do
    foo_test = [result: "positive"]
    {:ok, foo_test_json} = JSON.encode foo_test
    post("/devices/foo", foo_test_json)

    Cdp.Repo.create Cdp.Device.new(laboratory_id: meta[:laboratory].id, secret_key: "bar")

    bar_test = [result: "negative"]
    {:ok, bar_test_json} = JSON.encode bar_test
    post("/devices/bar", bar_test_json)

    conn = get("/api/updates?device=#{meta[:device].id}")
    assert conn.status == 200
    {:ok, [first]} = JSON.decode(conn.sent_body)
    assert HashDict.get(first, "result") == "positive"
  end

  test "filters by laboratory", meta do
    foo_test = [result: "positive"]
    {:ok, foo_test_json} = JSON.encode foo_test
    post("/devices/foo", foo_test_json)

    laboratory2 = Cdp.Repo.create Cdp.Laboratory.new(institution_id: meta[:institution].id, name: "baz")
    Cdp.Repo.create Cdp.Device.new(laboratory_id: laboratory2.id, secret_key: "bar")

    bar_test = [result: "negative"]
    {:ok, bar_test_json} = JSON.encode bar_test
    post("/devices/bar", bar_test_json)

    conn = get("/api/updates?laboratory=#{meta[:laboratory].id}")
    assert conn.status == 200
    {:ok, [first]} = JSON.decode(conn.sent_body)
    assert HashDict.get(first, "result") == "positive"
  end

  test "filters by institution", meta do
    foo_test = [result: "positive"]
    {:ok, foo_test_json} = JSON.encode foo_test
    post("/devices/foo", foo_test_json)

    laboratory2 = Cdp.Repo.create Cdp.Laboratory.new(institution_id: meta[:institution2].id, name: "baz")
    Cdp.Repo.create Cdp.Device.new(laboratory_id: laboratory2.id, secret_key: "bar")

    bar_test = [result: "negative"]
    {:ok, bar_test_json} = JSON.encode bar_test
    post("/devices/bar", bar_test_json)

    conn = get("/api/updates?institution=#{meta[:institution].id}")
    assert conn.status == 200
    {:ok, [first]} = JSON.decode(conn.sent_body)
    assert HashDict.get(first, "result") == "positive"
  end

  test "filters by gender" do
    test = [result: "positive", gender: "male"]
    {:ok, test_json} = JSON.encode test
    post("/devices/foo", test_json)

    test = [result: "negative", gender: "female"]
    {:ok, test_json} = JSON.encode test
    post("/devices/foo", test_json)

    conn = get("/api/updates?gender=male")
    assert conn.status == 200
    {:ok, [response] } = JSON.decode(conn.sent_body)
    assert HashDict.get(response, "result") == "positive"

    conn = get("/api/updates?gender=female")
    assert conn.status == 200
    {:ok, [response] } = JSON.decode(conn.sent_body)
    assert HashDict.get(response, "result") == "negative"
  end

  test "filters by age low" do
    test = [result: "positive", age: 10]
    {:ok, test_json} = JSON.encode test
    post("/devices/foo", test_json)

    test = [result: "negative", age: 20]
    {:ok, test_json} = JSON.encode test
    post("/devices/foo", test_json)

    conn = get("/api/updates?age_low=15")
    assert conn.status == 200
    {:ok, [response] } = JSON.decode(conn.sent_body)
    assert HashDict.get(response, "result") == "negative"

    conn = get("/api/updates?age_low=20")
    assert conn.status == 200
    {:ok, [response] } = JSON.decode(conn.sent_body)
    assert HashDict.get(response, "result") == "negative"

    conn = get("/api/updates?age_low=21")
    assert conn.status == 200
    {:ok, [] } = JSON.decode(conn.sent_body)
  end

  teardown(meta) do
    Enum.each [Cdp.Institution, Cdp.Laboratory, Cdp.Device, Cdp.TestResult], &Cdp.Repo.delete_all/1
    Tirexs.ElasticSearch.delete meta[:index_name], meta[:settings]
    Tirexs.ElasticSearch.delete meta[:index_name2], meta[:settings]
  end
end
