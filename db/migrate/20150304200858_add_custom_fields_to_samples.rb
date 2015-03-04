class AddCustomFieldsToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :custom_fields, :text
  end
end
