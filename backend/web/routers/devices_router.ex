defmodule DevicesRouter do
  use Dynamo.Router

  post "/:device_key" do
    Cdp.Report.create_and_enqueue(device_key, conn.req_body())
    conn.send(200, conn.req_body())
  end
end
