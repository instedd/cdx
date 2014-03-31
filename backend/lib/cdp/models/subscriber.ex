defmodule Cdp.Subscriber do
  use Ecto.Model

  queryable "subscribers" do
    field :name
    field :work_group_id, :integer
    field :auth_token
    field :callback_url
  end

  def find_by_work_group_id(work_group_id) do
    query = from s in Cdp.Subscriber,
      where: s.work_group_id == ^work_group_id,
      select: s
    Cdp.Repo.all(query)
  end
end

