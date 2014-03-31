defmodule Mix.Tasks.Rabbit.Reset do
  use Mix.Task
  @shortdoc "Reset the entire rabbit-mq server"
  def run(_) do
    System.cmd('rabbitmqctl stop_app')
    System.cmd('rabbitmqctl reset')
    System.cmd('rabbitmqctl start_app')
  end
end
