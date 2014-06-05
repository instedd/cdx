defmodule Device do
  use Ecto.Model
  import Ecto.Query

  schema "devices" do
    has_many(:devices_laboratories, DevicesLaboratories)
    belongs_to(:device_model, DeviceModel)
    has_many(:events, Event)
    belongs_to(:institution, Institution)
    field :name
    field :secret_key
  end

  def find_by_key(device_key) do
    query = from d in Device,
      where: d.secret_key == ^device_key,
      left_join: dm in d.device_model,
      left_join: dmm in dm.device_models_manifests,
      left_join: m in dmm.manifest,
      left_join: dl in d.devices_laboratories,
      left_join: l in dl.laboratory,
      select: {d, m, l}
    join_devices Repo.all(query)
  end

  def join_devices devices do
    Enum.reduce(devices, {1, [], []}, fn({device, manifest, laboratory}, {_, manifests, laboratories}) ->
      if(manifest != nil) do
        manifests = [manifest | manifests]
      end
      if(laboratory != nil) do
        laboratories = [laboratory | laboratories]
      end
      {device, manifests, laboratories}
    end)
  end
end
