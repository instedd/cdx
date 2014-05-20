class RenameDeviceModelToModel < ActiveRecord::Migration
  def change
    rename_table :device_models, :models
    rename_column(:device_models_manifests, :device_model_id, :model_id)
    rename_column(:devices, :device_model_id, :model_id)
    rename_table :device_models_manifests, :manifests_models
  end
end
