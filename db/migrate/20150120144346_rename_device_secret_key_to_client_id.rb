class RenameDeviceSecretKeyToClientId < ActiveRecord::Migration
  def change
    rename_column :activation_tokens, :device_secret_key, :client_id
  end
end
