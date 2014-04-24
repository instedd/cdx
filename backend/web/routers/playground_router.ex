defmodule PlaygroundRouter do
  use Dynamo.Router

  get "/" do
    devices = Cdp.Repo.all(Cdp.Device)
    conn = conn.assign(:devices, devices)
    render conn, "playground.html"
  end
end
