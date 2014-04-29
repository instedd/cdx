defmodule Cdp do
  use Application.Behaviour

  @doc """
  The application callback used to start this
  application and its Dynamos.
  """
  def start(_type, _args) do
    Cdp.Supervisor.start_link
  end
end

defmodule Cdp.Supervisor do
  use Supervisor.Behaviour

  def start_link do
    :supervisor.start_link({ :local, __MODULE__ }, __MODULE__, [])
  end

  def init([]) do
    :application.start :crypto
    :lager.start
    :ok = Elasticsearch.initialize
    tree = [
      worker(Repo, []),
      worker(Cdp.Dynamo, [[max_restarts: 5, max_seconds: 5]]),
    ]
    supervise(tree, strategy: :one_for_all)
  end
end
