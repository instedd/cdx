defmodule DevicesLaboratories do
  use Ecto.Model
  import Ecto.Query

  queryable "devices_laboratories", primary_key: false do
    belongs_to(:laboratory, Laboratory)
    belongs_to(:device, Device)
  end

  def find_all_by_device_id(device_id) do
    query = from dl in DevicesLaboratories,
      where: dl.secret_key == ^device_id,
      preload: :laboratory,
      select: dl
    Repo.all(query)
  end
end
