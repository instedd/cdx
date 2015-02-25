class AddInstitutionToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :institution_id, :integer
  end
end
