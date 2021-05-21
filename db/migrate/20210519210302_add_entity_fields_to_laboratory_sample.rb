class AddEntityFieldsToLaboratorySample < ActiveRecord::Migration
  def change
    add_column :laboratory_samples, :core_fields, :text
    add_column :laboratory_samples, :custom_fields, :text
    add_column :laboratory_samples, :sensitive_data, :binary

    add_column :laboratory_samples, :deleted_at, :datetime
    add_index :laboratory_samples, :deleted_at
  end
end
