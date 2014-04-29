defmodule Cdp.Device do
  use Ecto.Model
  import Ecto.Query

  queryable "devices" do
    has_many(:devices_laboratories, Cdp.DevicesLaboratories)
    has_many(:test_results, Cdp.TestResult)
    belongs_to(:institution, Cdp.Institution)
    field :name
    field :secret_key
  end

  def find_by_key(device_key) do
    query = from d in Cdp.Device,
      where: d.secret_key == ^device_key,
      preload: :devices_laboratories,
      select: d
    [device] = Cdp.Repo.all(query)
    device
  end
end
