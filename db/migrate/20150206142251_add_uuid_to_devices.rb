class AddUuidToDevices < ActiveRecord::Migration
  def change
    rename_column :devices, :secret_key, :uuid
    add_column :devices, :secret_key, :string
  end
end
