class AddInstitutionIdToDeviceModels < ActiveRecord::Migration
  def change
    add_column :device_models, :institution_id, :integer, null: true
  end
end
