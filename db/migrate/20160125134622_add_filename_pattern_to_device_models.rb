class AddFilenamePatternToDeviceModels < ActiveRecord::Migration
  def change
    add_column :device_models, :filename_pattern, :string
  end
end
