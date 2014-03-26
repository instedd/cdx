defmodule Cdp.WorkGroup do
  use Ecto.Model

  queryable "work_groups" do
    field :name
    field :user_id, :integer
  end

  def elasticsearch_index_name(work_group_id) do
    "cdp_work_group_#{work_group_id}_#{Mix.env}"
  end
end
