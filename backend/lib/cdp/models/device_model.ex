defmodule DeviceModel do
  use Ecto.Model

  queryable "device_models" do
    has_many(:device_models_manifests, DeviceModelsManifests, foreign_key: :device_model_id)
    has_many(:devices, Device)
    field :name
  end
end
