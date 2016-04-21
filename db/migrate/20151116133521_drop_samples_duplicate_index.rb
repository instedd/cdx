class DropSamplesDuplicateIndex < ActiveRecord::Migration
  def up
    remove_index "samples", name: "index_samples_on_institution_id_and_entity_id_hash"
  end

  def down
    add_index "samples", ["institution_id"], name: "index_samples_on_institution_id_and_entity_id_hash", using: :btree
  end
end
