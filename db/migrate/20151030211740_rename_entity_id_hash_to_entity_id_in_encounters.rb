class RenameEntityIdHashToEntityIdInEncounters < ActiveRecord::Migration
  def change
    rename_column :encounters, :entity_id_hash, :entity_id
  end
end
