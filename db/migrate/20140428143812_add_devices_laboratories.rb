class AddDevicesLaboratories < ActiveRecord::Migration
  def change
    create_table :devices_laboratories, id: false do |t|
      t.belongs_to :device
      t.belongs_to :laboratory
    end

    remove_column :devices, :laboratory_id
  end
end
