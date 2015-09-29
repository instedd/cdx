class AddNotAvailableSerialNumberToExistingDevices < ActiveRecord::Migration
  def up
    execute "UPDATE devices SET serial_number = 'n/a' WHERE serial_number IS NULL"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
