class AddIndicesToTransferPackages < ActiveRecord::Migration
  def change
    add_index :transfer_packages, :uuid, unique: true
    add_index :transfer_packages, :receiver_institution_id
    add_index :transfer_packages, :sender_institution_id
    add_index :transfer_packages, :created_at
  end
end
