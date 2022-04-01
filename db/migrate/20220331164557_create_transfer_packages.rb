class CreateTransferPackages < ActiveRecord::Migration
  def up
    create_table :transfer_packages do |t|
      t.belongs_to :receiver_institution,            null: false
      t.string     :uuid,                 limit: 36, null: false
      t.string     :recipient
      t.boolean    :includes_qc_info, default: false
    end

    change_table :sample_transfers do |t|
      t.belongs_to :transfer_package
    end
  end

  def down
    remove_column :sample_transfers, :transfer_package_id
    drop_table :transfer_packages
  end
end
