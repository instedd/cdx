class AddTypeToLaboratorySamples < ActiveRecord::Migration
  def change
    add_column :laboratory_samples, :sample_type, :string
  end
end
