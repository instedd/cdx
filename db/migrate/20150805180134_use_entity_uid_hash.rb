class UseEntityUidHash < ActiveRecord::Migration
  def change
    rename_column :patients, :patient_id_hash, :entity_uid_hash
    rename_column :samples, :sample_uid_hash, :entity_uid_hash
    rename_column :encounters, :encounter_id_hash, :entity_uid_hash
  end
end
