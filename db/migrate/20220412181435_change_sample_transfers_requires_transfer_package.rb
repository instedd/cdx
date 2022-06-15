class ChangeSampleTransfersRequiresTransferPackage < ActiveRecord::Migration
  def up
    change_column_null :sample_transfers, :transfer_package_id, false
  end

  def down
    change_column_null :sample_transfers, :transfer_package_id, true
  end
end
