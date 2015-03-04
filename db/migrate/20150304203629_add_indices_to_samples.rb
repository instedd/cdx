class AddIndicesToSamples < ActiveRecord::Migration
  def change
    add_index "samples", ["institution_id", "sample_uid_hash"]
    add_index "samples", ["uuid"]
  end
end
