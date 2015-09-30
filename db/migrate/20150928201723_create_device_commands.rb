class CreateDeviceCommands < ActiveRecord::Migration
  def change
    create_table :device_commands do |t|
      t.integer :device_id
      t.string :name
      t.string :command

      t.timestamps null: false
    end
  end
end
