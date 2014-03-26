defmodule DevicesRouter do
  use Dynamo.Router

  post "/:device_id" do
    {device_id, ""} = Integer.parse device_id

    Cdp.Report.create(device_id, conn.req_body())

    conn.send(200, conn.req_body())
  end
end
