defmodule CdpElixir do
  use Application.Behaviour

  @doc """
  The application callback used to start this
  application and its Dynamos.
  """
  def start(_type, _args) do
    CdpElixir.Sup.start_link
  end
end

defmodule CdpElixir.Sup do
  use Supervisor.Behaviour

  def start_link do
    :supervisor.start_link({ :local, __MODULE__ }, __MODULE__, [])
  end

  def init([]) do
    tree = [
      worker(CdpElixir.Repo, []),
      worker(CdpElixir.Dynamo, [[max_restarts: 5, max_seconds: 5]]),
    ]
    supervise(tree, strategy: :one_for_all)
  end
end
