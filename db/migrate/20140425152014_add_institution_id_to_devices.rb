class AddInstitutionIdToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :institution_id, :integer
  end
end
