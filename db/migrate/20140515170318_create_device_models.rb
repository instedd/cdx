class CreateDeviceModels < ActiveRecord::Migration
  def change
    create_table :device_models do |t|
      t.string :name

      t.timestamps
    end

    add_column :devices, :device_model_id, :integer
  end
end
