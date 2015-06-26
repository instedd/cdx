class AddCustomMappingsToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :custom_mappings, :text
  end
end
