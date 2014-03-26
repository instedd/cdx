defmodule ApplicationRouter do
  use Dynamo.Router

  prepare do
    # Pick which parts of the request you want to fetch
    # You can comment the line below if you don't need
    # any of them or move them to a forwarded router
    conn.fetch([:cookies, :params])
  end

  # It is common to break your Dynamo into many
  # routers, forwarding the requests between them:
  # forward "/posts", to: PostsRouter

  get "/devices/:device_id" do
    {device_id, ""} = Integer.parse device_id
    device = Cdp.Repo.get Cdp.Device, device_id

    conn = conn.assign(:title, "Welcome to device #{device.name}!")
    render conn, "index.html"
  end

  get "/section/:section" when section in ["foo", "about"] do
    render conn, "#{section}.html"
  end
end
