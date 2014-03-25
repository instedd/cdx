class RenameFacilityToDevice < ActiveRecord::Migration
  def change
    rename_table :facilities, :devices
  end
end
