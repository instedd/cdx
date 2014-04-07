class RenameWorkGroupToInstitution < ActiveRecord::Migration
  def up
    rename_table :work_groups, :institutions
    rename_column(:devices, :work_group_id, :laboratory_id)

    rename_column(:subscribers, :work_group_id, :institution_id)

    rename_column(:reports, :work_group_id, :institution_id)
    add_index(:reports, :institution_id)
  end

  def down
    rename_table :institutions, :work_groups
    rename_column(:devices, :laboratory_id, :work_group_id)

    rename_column(:subscribers, :institution_id, :work_group_id)

    remove_index(:reports, :institution_id)
    rename_column(:reports, :institution_id, :work_group_id)
  end
end
