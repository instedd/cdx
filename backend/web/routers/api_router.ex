defmodule ApiRouter do
  use Dynamo.Router

  get "/updates" do
    if String.length(conn.req_body()) == 0 do
      params = Dynamo.Connection.QueryParser.parse(conn.query_string())
    else
      {:ok, params} = JSON.decode conn.req_body()
    end
    test_results = Enum.map Cdp.TestResult.query(params), fn test_result -> HashDict.new(test_result["_source"]) end
    {:ok, test_results} = JSON.encode(test_results)
    conn.send(200, test_results)
  end
end
