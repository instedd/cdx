defmodule ApiRouter do
  require IEx
  use Dynamo.Router

  get "/events/" do
    get_events(conn)
  end

  post "/events/" do
    get_events(conn)
  end

  get "/events/:event_uuid/pii" do
    conn.send(200, JSEX.encode!(Event.pii_of(event_uuid)))
  end

  get "/events/:event_uuid/custom_fields" do
    conn.send(200, JSEX.encode!(Event.custom_fields_of(event_uuid)))
  end

  post "/devices/:device_key/events" do
    EventCreation.create(device_key, conn.req_body())
    conn.send(200, conn.req_body())
  end

  put "/events/:event_uuid/pii" do
    EventCreation.update_pii(event_uuid, JSEX.decode!(conn.req_body()))
    conn.send(200, conn.req_body())
  end

  defp get_events(conn) do
    params = Dynamo.Connection.QueryParser.parse(conn.query_string())

    if String.length(conn.req_body()) == 0 do
      post_body = %{}
    else
      {:ok, post_body} = JSEX.decode conn.req_body()
    end
    conn.send(200, JSEX.encode!(EventFiltering.query(params, post_body)))
  end
end
