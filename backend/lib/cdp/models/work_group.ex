defmodule Cdp.WorkGroup do
  use Ecto.Model

  queryable "work_groups" do
    field :name
    field :user_id, :integer
  end
end
