defmodule ApiRouter do
  use Dynamo.Router

  get "/updates" do
    {:ok, params} = JSON.decode conn.req_body()
    test_results = Enum.map Cdp.TestResult.since(params["since"]), fn test_result -> HashDict.new(test_result["_source"]) end
    {:ok, test_results} = JSON.encode(test_results)
    conn.send(200, test_results)
  end
end
