class CreateDeviceEventsEvents < ActiveRecord::Migration
  def change
    create_table :device_events_events do |t|
      t.belongs_to :device_event, index: true
      t.belongs_to :event, index: true
    end
  end
end
