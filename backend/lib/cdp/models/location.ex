defmodule Location do
  use Ecto.Model

  queryable "locations" do
    has_many(:laboratories, Laboratory)
    field :name
    field :rgt
    field :lft
    field :depth
    field :parent_id, :integer
    field :lat
    field :lng
  end

  def common_root([location | []]) do
    location
  end

  def common_root([nil]) do
    nil
  end

  def common_root([location| [other | t]]) do
    root = common_root location, other
    common_root [root | t]
  end

  def common_root(nil, _) do
    nil
  end

  def common_root(_, nil) do
    nil
  end

  def common_root(location, other) do
    if location.id == other.id do
      location
    end || common_root(Repo.get(Location, location.parent_id), other) || common_root(location, Repo.get(Location, other.parent_id))
  end

  def with_parents(nil) do
    []
  end

  def with_parents(location) do
    [location.id | with_parents(Repo.get(Location, location.parent_id))]
  end
end
