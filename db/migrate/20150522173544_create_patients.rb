class CreatePatients < ActiveRecord::Migration
  def change
    create_table :patients do |t|
      t.binary :sensitive_data
      t.text :custom_fields
      t.text :indexed_fields
      t.string :patient_id_hash
      t.string :uuid
      t.references :institution, index: true

      t.timestamps
    end
  end
end
