defmodule ApiRouter do
  use Dynamo.Router

  get "/results/" do
    if String.length(conn.req_body()) == 0 do
      params = Dynamo.Connection.QueryParser.parse(conn.query_string())
    else
      {:ok, params} = JSON.decode conn.req_body()
    end
    conn.send(200, JSON.encode!(TestResult.query(params)))
  end

  get "/results/:result_uuid/pii" do
    conn.send(200, JSON.encode!(TestResult.find_by_uuid(result_uuid)))
  end

  post "/devices/:device_key/results" do
    TestResult.create_and_enqueue(device_key, conn.req_body())
    conn.send(200, conn.req_body())
  end

  put "/results/:result_uuid/pii" do
    TestResult.update_pii(result_uuid, JSON.decode!(conn.req_body()))
    conn.send(200, conn.req_body())
  end
end
