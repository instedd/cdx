class AddTimeZoneToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :time_zone, :string
  end
end
