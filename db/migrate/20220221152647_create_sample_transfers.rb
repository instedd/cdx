class CreateSampleTransfers < ActiveRecord::Migration
  def change
    create_table :sample_transfers do |t|
      t.references :sample
      t.references :sender_institution
      t.references :receiver_institution
      t.datetime :confirmed_at

      t.timestamps null: false
    end
    add_index :sample_transfers, :sample_id
    add_index :sample_transfers, :sender_institution_id
    add_index :sample_transfers, :receiver_institution_id
    add_index :sample_transfers, :confirmed_at
  end
end
