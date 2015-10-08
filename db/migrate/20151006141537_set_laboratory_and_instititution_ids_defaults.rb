class SetLaboratoryAndInstititutionIdsDefaults < ActiveRecord::Migration

  def up
    connection.execute <<-SQL
      UPDATE test_results
      SET test_results.laboratory_id =
        (SELECT devices.laboratory_id FROM devices
         WHERE devices.id = test_results.device_id)
    SQL

    connection.execute <<-SQL
      UPDATE test_results
      SET test_results.institution_id =
        (SELECT devices.institution_id FROM devices
         WHERE devices.id = test_results.device_id)
    SQL
  end

  def down
    # Nothing to do
  end

end
