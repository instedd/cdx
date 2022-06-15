class AddConfirmedAtToTransferPackages < ActiveRecord::Migration
  def up
    add_column :transfer_packages, :confirmed_at, :datetime, null: true
    add_index :transfer_packages, :confirmed_at

    TransferPackage.reset_column_information
  end

  def down
    remove_column :transfer_packages, :confirmed_at, :datetime
  end
end
