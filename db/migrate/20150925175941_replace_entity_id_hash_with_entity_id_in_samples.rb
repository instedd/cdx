class ReplaceEntityIdHashWithEntityIdInSamples < ActiveRecord::Migration
  def change
    remove_column :samples, :entity_id_hash, :string
    add_column :samples, :entity_id, :string

    add_index :samples, [:institution_id, :entity_id]
  end
end
