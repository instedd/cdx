class AddFtpPassiveToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :ftp_passive, :boolean
  end
end
