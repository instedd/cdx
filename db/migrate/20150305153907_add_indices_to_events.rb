class AddIndicesToEvents < ActiveRecord::Migration
  def change
    add_index "events", ["sample_id"]
    add_index "events", ["uuid"]
  end
end
