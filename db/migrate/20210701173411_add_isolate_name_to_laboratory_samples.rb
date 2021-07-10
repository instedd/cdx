class AddIsolateNameToLaboratorySamples < ActiveRecord::Migration
  def change
    add_column :laboratory_samples, :isolate_name, :string
    add_index :laboratory_samples, :isolate_name
  end
end
