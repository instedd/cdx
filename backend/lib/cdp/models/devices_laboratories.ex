defmodule DevicesLaboratories do
  use Ecto.Model
  import Ecto.Query

  queryable "devices_laboratories", primary_key: false do
    belongs_to(:laboratory, Laboratory)
    belongs_to(:device, Device)
  end
end
