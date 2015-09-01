class Rename < ActiveRecord::Migration
  def change
    rename_column :encounters, :entity_uid_hash, :entity_id_hash
    rename_column :patients, :entity_uid_hash, :entity_id_hash
    rename_column :samples, :entity_uid_hash, :entity_id_hash
  end
end
