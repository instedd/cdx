class CreateFileMessages < ActiveRecord::Migration
  def change
    create_table :file_messages do |t|
      t.string :filename
      t.string :status
      t.text :message
      t.integer :device_id
      t.integer :device_message_id
      t.string :ftp_hostname
      t.string :ftp_username
      t.string :ftp_password
      t.string :ftp_directory
      t.integer :ftp_port
    end

    add_index :file_messages, [:ftp_hostname, :ftp_port, :ftp_directory, :status], name: 'index_file_messages_on_ftp_and_status'
    add_index :file_messages, [:device_id]
  end
end
