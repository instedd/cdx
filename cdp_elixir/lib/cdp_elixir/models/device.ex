defmodule CdpElixir.Device do
  use Ecto.Model

  queryable "devices" do
    field :name
    field :work_group_id, :integer
  end
end
