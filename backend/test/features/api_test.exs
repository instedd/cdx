defmodule ApiTest do
  use Timex
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  setup do
    institution = Cdp.Repo.create Cdp.Institution.new(name: "baz")
    laboratory = Cdp.Repo.create Cdp.Laboratory.new(institution_id: institution.id, name: "bar")
    device = Cdp.Repo.create Cdp.Device.new(laboratory_id: laboratory.id, secret_key: "foo")
    settings = Tirexs.ElasticSearch.Config.new()
    index_name = Cdp.Institution.elasticsearch_index_name(institution.id)
    {:ok, institution: institution, device: device, settings: settings, index_name: index_name}
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

  teardown(meta) do
    Enum.each [Cdp.Institution, Cdp.Device, Cdp.TestResult], &Cdp.Repo.delete_all/1
    Tirexs.ElasticSearch.delete meta[:index_name], meta[:settings]
  end
end
