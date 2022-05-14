class AddTimestampsToTransferPackages < ActiveRecord::Migration
  def up
    change_table :transfer_packages do |t|
      t.timestamps
    end

    connection.execute "UPDATE transfer_packages SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL;"
    connection.execute "UPDATE transfer_packages SET updated_at = CURRENT_TIMESTAMP WHERE updated_at IS NULL;"
  end

  def down
    change_table :transfer_packages do |t|
      t.remove :created_at
      t.remove :updated_at
    end
  end
end
