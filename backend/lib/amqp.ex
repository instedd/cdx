defmodule Amqp do
  defrecord :amqp_msg, Record.extract(:amqp_msg, from: "deps/amqp_client/include/amqp_client.hrl")
  defrecord :amqp_params_network, Record.extract(:amqp_params_network, from: "deps/amqp_client/include/amqp_client.hrl")
  defrecord :amqp_params_direct, Record.extract(:amqp_params_direct, from: "deps/amqp_client/include/amqp_client.hrl")
  defrecord :amqp_params_info, Record.extract(:amqp_params_info, from: "deps/amqp_client/include/amqp_client.hrl")
end
