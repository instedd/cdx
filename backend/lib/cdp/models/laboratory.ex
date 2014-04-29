defmodule Laboratory do
  use Ecto.Model

  queryable "laboratories" do
    belongs_to(:institution, Institution)
    has_many(:devices, Device)
    field :name
  end
end
