class CreateBatches < ActiveRecord::Migration
  def change
    create_table :batches do |t|
      t.string :uuid
      t.text :core_fields
      t.text :custom_fields
      t.binary :sensitive_data
      t.string :isolate_name

      t.datetime :deleted_at
      t.references :institution, index: true

      t.timestamps null: false
    end

    add_index :batches, :deleted_at
    add_index :batches, :isolate_name
  end
end

