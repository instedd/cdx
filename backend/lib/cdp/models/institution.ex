defmodule Cdp.Institution do
  use Ecto.Model

  queryable "institutions" do
    has_many(:subscribers, Cdp.Subscriber)
    has_many(:laboratories, Cdp.Laboratory)
    field :name
    field :user_id, :integer
  end

  def elasticsearch_index_name(institution_id) do
    "cdp_institution_#{institution_id}_#{Mix.env}"
  end
end
