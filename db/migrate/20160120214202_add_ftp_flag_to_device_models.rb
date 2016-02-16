class AddFtpFlagToDeviceModels < ActiveRecord::Migration
  def change
    add_column :device_models, :supports_ftp, :boolean
  end
end
