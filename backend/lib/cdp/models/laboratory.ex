defmodule Laboratory do
  use Ecto.Model

  schema "laboratories" do
    belongs_to(:institution, Institution)
    belongs_to(:location, Location)
    has_many(:devices, Device)
    field :name
  end
end
