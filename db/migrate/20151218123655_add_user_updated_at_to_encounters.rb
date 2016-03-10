class AddUserUpdatedAtToEncounters < ActiveRecord::Migration
  def change
    add_column :encounters, :user_updated_at, :datetime
  end
end
