defmodule ApiRouter do
  use Dynamo.Router

  get "/results/" do
    get_results(conn)
  end

  post "/results/" do
    get_results(conn)
  end

  get "/results/:result_uuid/pii" do
    conn.send(200, JSEX.encode!(TestResult.pii_of(result_uuid)))
  end

  get "/results/:result_uuid/custom_fields" do
    conn.send(200, JSEX.encode!(TestResult.custom_fields_of(result_uuid)))
  end

  post "/devices/:device_key/results" do
    TestResultCreation.create(device_key, conn.req_body())
    conn.send(200, conn.req_body())
  end

  put "/results/:result_uuid/pii" do
    TestResultCreation.update_pii(result_uuid, JSEX.decode!(conn.req_body()))
    conn.send(200, conn.req_body())
  end

  defp get_results(conn) do
    params = Dynamo.Connection.QueryParser.parse(conn.query_string())

    if String.length(conn.req_body()) == 0 do
      post_body = %{}
    else
      {:ok, post_body} = JSEX.decode conn.req_body()
    end
    conn.send(200, JSEX.encode!(TestResultFiltering.query(params, post_body)))
  end
end
