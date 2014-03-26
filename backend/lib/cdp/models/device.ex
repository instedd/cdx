defmodule Cdp.Device do
  use Ecto.Model
  import Ecto.Query

  queryable "devices" do
    field :name
    field :work_group_id, :integer
    field :secret_key
  end

  def find_by_key(device_key) do
    query = from d in Cdp.Device,
          where: d.secret_key == ^device_key,
         select: d
    [device] = Cdp.Repo.all(query)
    device
  end
end
