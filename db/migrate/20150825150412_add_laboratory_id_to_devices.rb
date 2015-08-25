class AddLaboratoryIdToDevices < ActiveRecord::Migration
  def up
    add_column :devices, :laboratory_id, :integer
    drop_table :devices_laboratories
  end

  def down
    create_table "devices_laboratories", id: false, force: :cascade do |t|
      t.integer "device_id",     limit: 4
      t.integer "laboratory_id", limit: 4
    end
    remove_column :devices, :laboratory_id, :integer
  end
end
