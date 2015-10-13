class AddSupportsActivationToDeviceModel < ActiveRecord::Migration
  def change
    add_column :device_models, :supports_activation, :boolean
  end
end
