class MigrateSecretKeyToSecretKeyHashInDevices < ActiveRecord::Migration
  def up
    devices = execute "SELECT id, secret_key_hash FROM devices"
    devices.each do |id, secret_key|
      execute "UPDATE devices SET secret_key_hash = '#{MessageEncryption.hash(secret_key)}' WHERE id = #{id}"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
