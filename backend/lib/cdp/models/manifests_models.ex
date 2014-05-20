defmodule ManifestsModels do
  use Ecto.Model

  queryable "manifests_models", primary_key: false do
    belongs_to(:model, Model)
    belongs_to(:manifest, Manifest)
  end
end
