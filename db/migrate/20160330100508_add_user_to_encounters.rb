class AddUserToEncounters < ActiveRecord::Migration
  def change
    add_reference :encounters, :user, index: true, foreign_key: true
  end
end
