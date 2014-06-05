defmodule DeviceModelsManifests do
  use Ecto.Model

  schema "device_models_manifests", primary_key: false do
    belongs_to(:device_model, DeviceModel)
    belongs_to(:manifest, Manifest)
  end
end
