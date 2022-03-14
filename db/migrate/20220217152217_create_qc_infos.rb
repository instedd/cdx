class CreateQcInfos < ActiveRecord::Migration
  def change
    create_table :qc_infos do |t|
      t.string :uuid
      t.string :batch_number
      t.text :core_fields
      t.text :custom_fields
      t.binary :sensitive_data
      t.integer :sample_qc_id

      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :qc_infos, :batch_number
    add_index :qc_infos, :uuid
  end
end