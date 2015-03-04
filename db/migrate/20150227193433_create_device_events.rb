class CreateDeviceEvents < ActiveRecord::Migration
  def change
    create_table :device_events do |t|
      t.binary :raw_data
      t.references :device, index: true
      t.boolean :index_failed
      t.text :index_failure_reason

      t.timestamps
    end
  end
end
