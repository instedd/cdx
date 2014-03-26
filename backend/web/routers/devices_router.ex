defmodule DevicesRouter do
  use Dynamo.Router

  post "/:device_key" do
    Cdp.Report.create(device_key, conn.req_body())
    conn.send(200, conn.req_body())
  end
end
