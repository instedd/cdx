class RenameSecretKeyToSecretKeyHashInDevices < ActiveRecord::Migration
  def change
    rename_column :devices, :secret_key, :secret_key_hash
  end
end
