class AddSupportUrlToDeviceModels < ActiveRecord::Migration
  def change
    add_column :device_models, :support_url, :string
  end
end
