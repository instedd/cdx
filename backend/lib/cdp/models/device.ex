defmodule Device do
  use Ecto.Model
  import Ecto.Query

  queryable "devices" do
    has_many(:devices_laboratories, DevicesLaboratories)
    has_many(:test_results, TestResult)
    belongs_to(:institution, Institution)
    field :name
    field :secret_key
  end

  def find_by_key(device_key) do
    query = from d in Device,
      where: d.secret_key == ^device_key,
      preload: [devices_laboratories: [laboratory: :location]],
      select: d
    [device] = Repo.all(query)
    device
  end
end
