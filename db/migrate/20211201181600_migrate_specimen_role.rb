class MigrateSpecimenRole < ActiveRecord::Migration
  def up
    Sample.find_each do |sample|
      next if sample.specimen_role.nil?
      sample.save
    end
  end

  def down
    # only udpate physical column in the database to not overwrite the value stored in core_fields
    connection.exec_update(<<-EOQ, "SQL", [[nil,'']])
      UPDATE  samples
      SET    specimen_role = ''
    EOQ
  end

end