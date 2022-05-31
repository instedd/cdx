class ChangeBoxInstitutionNull < ActiveRecord::Migration
  def up
    change_column_null :boxes, :institution_id, true
  end

  def down
    change_column_null :boxes, :institution_id, false
  end
end
