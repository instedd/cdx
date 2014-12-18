class CreateDeviceSshKeys < ActiveRecord::Migration
  def change
    create_table :device_ssh_keys do |t|
      t.text :key
      t.references :device, index: true

      t.timestamps
    end
  end
end
