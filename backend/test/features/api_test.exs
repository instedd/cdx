defmodule ApiTest do
  use Timex
  use Cdp.TestCase
  use Dynamo.HTTP.Case
  require Tirexs.Search

  setup do
    work_group = Cdp.Repo.create Cdp.WorkGroup.new
    device = Cdp.Repo.create Cdp.Device.new(work_group_id: work_group.id, secret_key: "foo")
    first_report = "{\"result\": \"positive\"}"
    second_report = "{\"result\": \"negative\"}"
    settings = Tirexs.ElasticSearch.Config.new()
    index_name = Cdp.WorkGroup.elasticsearch_index_name(work_group.id)
    {:ok, work_group: work_group, device: device, first_report: first_report, second_report: second_report, settings: settings, index_name: index_name}
  end

  test "checks for new reports since a date", meta do
    before_first_report = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")
    :timer.sleep(1000)
    post("/devices/foo", meta[:first_report])

    conn = get("/api/updates", "{\"since\": \"#{before_first_report}\"}")
    assert conn.status == 200
    {:ok, [response] } = JSON.decode(conn.sent_body)
    assert HashDict.get(response,"result") == "positive"

    :timer.sleep(1000)
    after_first_report = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    post("/devices/foo", meta[:second_report])

    conn = get("/api/updates", "{\"since\": \"#{after_first_report}\"}")
    assert conn.status == 200
    {:ok, [response] } = JSON.decode(conn.sent_body)
    assert HashDict.get(response,"result") == "negative"

    conn = get("/api/updates", "{\"since\": \"#{before_first_report}\"}")
    assert conn.status == 200
    {:ok, [first | [second]] } = JSON.decode(conn.sent_body)
    assert HashDict.get(first,"result") == "positive"
    assert HashDict.get(second,"result") == "negative"

    :timer.sleep(1000)
    after_second_report = DateFormat.format!(Date.from(:calendar.universal_time()), "{ISO}")

    conn = get("/api/updates", "{\"since\": \"#{after_second_report}\"}")
    assert conn.status == 200
    {:ok, [] } = JSON.decode(conn.sent_body)
  end

  teardown(meta) do
    Enum.each [Cdp.WorkGroup, Cdp.Device, Cdp.Report], &Cdp.Repo.delete_all/1
    Tirexs.ElasticSearch.delete meta[:index_name], meta[:settings]
  end
end
