class AddUuidToInstitutionsAndSites < ActiveRecord::Migration
  def change
    add_column :institutions, :uuid, :string
    add_column :laboratories, :uuid, :string
  end
end
