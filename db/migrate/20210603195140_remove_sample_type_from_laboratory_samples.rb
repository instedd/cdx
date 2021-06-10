class RemoveSampleTypeFromLaboratorySamples < ActiveRecord::Migration
  def change
    remove_column :laboratory_samples, :sample_type, :string
  end
end
