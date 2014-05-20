class RenameModelToDeviceModel < ActiveRecord::Migration
  def change
    rename_table :models, :device_models
    rename_column :manifests_models, :model_id, :device_model_id
    rename_column :devices, :model_id, :device_model_id
    rename_table :manifests_models, :device_models_manifests
  end
end
