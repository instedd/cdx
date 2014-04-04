defmodule ApiRouter do
  use Dynamo.Router

  get "/updates" do
    {:ok, params} = JSON.decode conn.req_body()
    reports = Enum.map Cdp.Report.since(params["since"]), fn(report) -> HashDict.new(report["_source"]) end
    {:ok, reports} = JSON.encode(reports)
    conn = conn.send(200, reports)
  end
end
