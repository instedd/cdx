defmodule Cdp.Device do
  use Ecto.Model
  import Ecto.Query

  queryable "devices" do
    belongs_to(:laboratory, Cdp.Laboratory)
    has_many(:test_results, Cdp.TestResult)
    field :name
    field :secret_key
  end

  def find_by_key(device_key) do
    query = from d in Cdp.Device,
      where: d.secret_key == ^device_key,
      preload: :laboratory,
      select: d
    [device] = Cdp.Repo.all(query)
    device
  end
end
