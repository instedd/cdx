class AddTypeToLaboratorySamples < ActiveRecord::Migration
  def change
    add_column :laboratory_samples, :type, :string
  end
end
