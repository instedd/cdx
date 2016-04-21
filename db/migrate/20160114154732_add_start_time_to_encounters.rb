class AddStartTimeToEncounters < ActiveRecord::Migration
  def change
    add_column :encounters, :start_time, :datetime
  end
end
