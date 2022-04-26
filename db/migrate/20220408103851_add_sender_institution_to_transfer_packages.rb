class AddSenderInstitutionToTransferPackages < ActiveRecord::Migration
  def up
    add_reference :transfer_packages, :sender_institution, null: true

    TransferPackage.reset_column_information

    # Fill sender_institution on existing packages
    TransferPackage.find_each do |package|
      package.update_columns(
        sender_institution_id: package.sample_transfers.take.sender_institution_id,
      )
    end

    change_column_null :transfer_packages, :sender_institution_id, false
  end

  def down
    remove_reference :transfer_packages, :sender_institution
  end
end
