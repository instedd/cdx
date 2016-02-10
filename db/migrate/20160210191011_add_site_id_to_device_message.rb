class AddSiteIdToDeviceMessage < ActiveRecord::Migration
  def change
    add_reference :device_messages, :site, index: true, foreign_key: true
  end
end
