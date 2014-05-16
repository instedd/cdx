defmodule DeviceModel do
  use Ecto.Model

  queryable "device_models" do
    has_many(:device_models_manifests, DeviceModelsManifests)
    has_many(:devices, Device)
    field :name
  end
end
