class AddAttachmentPictureToDeviceModels < ActiveRecord::Migration
  def self.up
    change_table :device_models do |t|
      t.attachment :picture
    end
  end

  def self.down
    remove_attachment :device_models, :picture
  end
end
