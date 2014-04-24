defmodule PlaygroundRouter do
  use Dynamo.Router

  get "/" do
    devices = Cdp.Repo.all(Cdp.Device)
    options = Enum.reduce devices, "", fn(device, str) ->
      str <> "<option value=\"#{device.secret_key}\">#{device.name}</option>"
    end

    conn = conn.assign(:devices, options)
    render conn, "playground.html"
  end
end
