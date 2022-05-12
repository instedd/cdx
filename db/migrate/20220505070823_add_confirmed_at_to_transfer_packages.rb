class AddConfirmedAtToTransferPackages < ActiveRecord::Migration
  def up
    add_column :transfer_packages, :confirmed_at, :datetime, null: true
    add_index :transfer_packages, :confirmed_at

    TransferPackage.reset_column_information

    # Fill confirmed_at on existing packages if their sample transfers have been confirmed
    TransferPackage.find_each do |package|
      if confirmed_at = package.sample_transfers.map(&:confirmed_at).compact.max
        package.update_columns(
          confirmed_at: confirmed_at,
        )
      end
    end
  end

  def down
    remove_column :transfer_packages, :confirmed_at, :datetime
  end
end
