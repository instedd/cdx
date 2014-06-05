defmodule DevicesLaboratories do
  use Ecto.Model

  schema "devices_laboratories", primary_key: false do
    belongs_to(:laboratory, Laboratory)
    belongs_to(:device, Device)
  end
end
