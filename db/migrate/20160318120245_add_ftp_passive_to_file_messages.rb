class AddFtpPassiveToFileMessages < ActiveRecord::Migration
  def change
    add_column :file_messages, :ftp_passive, :boolean
  end
end
