config :dynamo,
  # In production, modules are compiled up-front.
  compile_on_demand: false,
  reload_modules: false

config :server,
  port: 8888,
  acceptors: 100,
  max_connections: 10000

# config :ssl,
#  port: 8889,
#  keyfile: "/var/www/key.pem",
#  certfile: "/var/www/cert.pem"

config :rabbit_amqp,
  user: "guest",
  pass: "guest",
  vhost: "/cdp_prod",
  subscribers_exchange: "prod_cdp_subscribers_exchange",
  subscribers_queue: "prod_cdp_subscribers_queue"
