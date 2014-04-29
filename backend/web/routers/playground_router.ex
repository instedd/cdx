defmodule PlaygroundRouter do
  use Dynamo.Router

  get "/" do
    devices = Repo.all(Device)
    conn = conn.assign(:devices, devices)
    render conn, "playground.html"
  end
end
