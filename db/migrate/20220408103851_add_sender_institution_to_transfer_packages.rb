class AddSenderInstitutionToTransferPackages < ActiveRecord::Migration[5.0]
  def up
    add_reference :transfer_packages, :sender_institution, null: true

    connection.execute <<-SQL
    UPDATE transfer_packages
    INNER JOIN sample_transfers ON sample_transfers.transfer_package_id = transfer_packages.id
    SET transfer_packages.sender_institution_id = sample_transfers.sender_institution_id;
    SQL

    change_column_null :transfer_packages, :sender_institution_id, false
  end

  def down
    remove_reference :transfer_packages, :sender_institution
  end
end
