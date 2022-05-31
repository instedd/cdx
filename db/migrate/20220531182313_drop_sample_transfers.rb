class DropSampleTransfers < ActiveRecord::Migration
  def change
    drop_table :sample_transfers, force: :cascade do |t|
      t.integer  "sample_id",               limit: 4
      t.integer  "sender_institution_id",   limit: 4
      t.integer  "receiver_institution_id", limit: 4
      t.datetime "confirmed_at"
      t.datetime "created_at",                        null: false
      t.datetime "updated_at",                        null: false
      t.integer  "transfer_package_id",     limit: 4, null: false
    end
  end
end
