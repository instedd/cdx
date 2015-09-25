class CreateDeviceLogs < ActiveRecord::Migration
  def change
    create_table :device_logs do |t|
      t.integer :device_id
      t.text :message

      t.timestamps
    end
  end
end
