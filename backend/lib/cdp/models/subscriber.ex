defmodule Subscriber do
  use Ecto.Model

  schema "subscribers" do
    belongs_to(:institution, Institution)
    field :name
    field :auth_token
    field :callback_url
  end

  def find_by_institution_id(institution_id) do
    query = from s in Subscriber,
      where: s.institution_id == ^institution_id,
      select: s
    Repo.all(query)
  end
end

