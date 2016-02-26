class AddAttachmentSetupInstructionsToDeviceModels < ActiveRecord::Migration
  def self.up
    change_table :device_models do |t|
      t.attachment :setup_instructions
    end
  end

  def self.down
    remove_attachment :device_models, :setup_instructions
  end
end
