config :dynamo,
  # For testing we compile modules on demand,
  # but there isn't a need to reload them.
  compile_on_demand: true,
  reload_modules: false

config :server, port: 8888

config :rabbit_amqp,
  user: "guest",
  pass: "guest",
  vhost: "/cdp_test",
  subscribers_exchange: "test_cdp_subscribers_exchange",
  subscribers_queue: "test_cdp_subscribers_queue"
