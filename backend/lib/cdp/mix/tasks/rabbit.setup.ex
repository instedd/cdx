defmodule Mix.Tasks.Rabbit.Setup do
  use Mix.Task
  @shortdoc "Creates the user and vhost for the current environment configuration"
  def run(_) do
    amqp_config = Cdp.Dynamo.config[:rabbit_amqp]
    System.cmd('rabbitmqctl add_user #{amqp_config[:user]} #{amqp_config[:pass]}')
    System.cmd('rabbitmqctl add_vhost #{amqp_config[:vhost]}')
    System.cmd('rabbitmqctl set_permissions -p #{amqp_config[:vhost]} #{amqp_config[:user]} ".*" ".*" ".*"')
  end
end
