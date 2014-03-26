class AddSecretKeyToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :secret_key, :string
  end
end
