class ChangeSampleTransfersRequiresTransferPackage < ActiveRecord::Migration
  def up
    # Create packages for existing transfers
    SampleTransfer.where(transfer_package_id: nil).find_each do |transfer|
      package = TransferPackage.create(
        sender_institution: transfer.sender_institution,
        receiver_institution: transfer.receiver_institution,
      )
      transfer.update_columns(
        transfer_package_id: package.id,
      )
    end

    change_column_null :sample_transfers, :transfer_package_id, false
  end

  def down
    change_column_null :sample_transfers, :transfer_package_id, true
  end
end
