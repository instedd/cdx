defmodule Cdp.Laboratory do
  use Ecto.Model

  queryable "laboratories" do
    belongs_to(:institution, Cdp.Institution)
    has_many(:devices, Cdp.Device)
    field :name
  end
end
