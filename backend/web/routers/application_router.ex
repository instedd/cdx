defmodule ApplicationRouter do
  use Dynamo.Router

  prepare do
    # Pick which parts of the request you want to fetch
    # You can comment the line below if you don't need
    # any of them or move them to a forwarded router
    conn.fetch([:cookies, :params, :body])
  end

  forward "/devices", to: DevicesRouter
  forward "/api", to: ApiRouter
  forward "/playground", to: PlaygroundRouter
end
