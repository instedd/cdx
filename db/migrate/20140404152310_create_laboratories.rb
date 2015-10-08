class CreateSites < ActiveRecord::Migration
  def change
    create_table :laboratories do |t|
      t.string   "name"
      t.integer  "institution_id"
      t.string   "address"
      t.string   "city"
      t.string   "state"
      t.string   "zip_code"
      t.string   "country"
      t.string   "region"
      t.float    "lat"
      t.float    "lng"
      t.integer  "location_id"
      t.timestamps
    end
  end
end
