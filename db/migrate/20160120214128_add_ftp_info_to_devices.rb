class AddFtpInfoToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :ftp_hostname,  :string
    add_column :devices, :ftp_username,  :string
    add_column :devices, :ftp_password,  :string
    add_column :devices, :ftp_directory, :string
    add_column :devices, :ftp_port, :integer
  end
end
