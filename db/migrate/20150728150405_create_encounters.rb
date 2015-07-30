class CreateEncounters < ActiveRecord::Migration
  def change
    create_table :encounters do |t|
      t.integer :institution_id
      t.integer :patient_id
      t.string :uuid
      t.string :encounter_id_hash
      t.binary :sensitive_data
      t.text :custom_fields
      t.text :indexed_fields

      t.timestamps
    end

    add_column :test_results, :encounter_id, :integer
    add_column :samples, :encounter_id, :integer
  end
end
