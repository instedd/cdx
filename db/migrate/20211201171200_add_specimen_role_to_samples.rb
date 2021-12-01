class AddSpecimenRoleToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :specimen_role, :string
    add_index :samples, :specimen_role
  end
end
