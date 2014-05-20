defmodule Model do
  use Ecto.Model

  queryable "models" do
    has_many(:manifests_models, ManifestsModels)
    has_many(:devices, Device)
    field :name
  end
end
