defmodule ApiTest do
  use Timex
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  setup do
    institution = Cdp.Repo.create Cdp.Institution.new(name: "baz")
    laboratory = Cdp.Repo.create Cdp.Laboratory.new(institution_id: institution.id, name: "bar")
    device = Cdp.Repo.create Cdp.Device.new(laboratory_id: laboratory.id, secret_key: "foo")
    {:ok, first_test} = JSON.encode [result: "positive"]
    {:ok, second_test} = JSON.encode [result: "negative"]
    settings = Tirexs.ElasticSearch.Config.new()
    index_name = Cdp.Institution.elasticsearch_index_name(institution.id)
    {:ok, institution: institution, device: device, first_test: first_test, second_test: second_test, settings: settings, index_name: index_name}
  end

  test "checks for new tests since a date", meta do
    before_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    post("/devices/foo", meta[:first_test])

    conn = get("/api/updates", "{\"since\": \"#{before_first_test}\"}")
    assert conn.status == 200
    {:ok, [response] } = JSON.decode(conn.sent_body)
    assert HashDict.get(response,"result") == "positive"

    :timer.sleep(1000)
    after_first_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    post("/devices/foo", meta[:second_test])

    conn = get("/api/updates", "{\"since\": \"#{after_first_test}\"}")
    assert conn.status == 200
    {:ok, [response] } = JSON.decode(conn.sent_body)
    assert HashDict.get(response,"result") == "negative"

    conn = get("/api/updates", "{\"since\": \"#{before_first_test}\"}")
    assert conn.status == 200
    {:ok, [first, second] } = JSON.decode(conn.sent_body)
    assert HashDict.get(first,"result") == "positive"
    assert HashDict.get(second,"result") == "negative"

    :timer.sleep(1000)
    after_second_test = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    conn = get("/api/updates", "{\"since\": \"#{after_second_test}\"}")
    assert conn.status == 200
    {:ok, [] } = JSON.decode(conn.sent_body)
  end

  teardown(meta) do
    Enum.each [Cdp.Institution, Cdp.Device, Cdp.TestResult], &Cdp.Repo.delete_all/1
    Tirexs.ElasticSearch.delete meta[:index_name], meta[:settings]
  end
end
