defmodule DevicesRouter do
  use Dynamo.Router

  post "/:device_key" do
    Cdp.Report.create(device_key, conn.req_body())

    amqp_config = Cdp.Dynamo.config[:rabbit_amqp]
    amqp = Exrabbit.Utils.connect
    channel = Exrabbit.Utils.channel amqp
    Exrabbit.Utils.declare_exchange channel, amqp_config[:subscribers_exchange]
    Exrabbit.Utils.publish channel, amqp_config[:subscribers_exchange], "", conn.req_body()

    conn.send(200, conn.req_body())
  end
end
