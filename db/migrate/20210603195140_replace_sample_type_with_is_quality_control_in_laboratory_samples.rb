class ReplaceSampleTypeWithIsQualityControlInLaboratorySamples < ActiveRecord::Migration
  def change
    remove_column :laboratory_samples, :sample_type, :string
    add_column :laboratory_samples, :is_quality_control, :boolean, :default => false
  end
end
