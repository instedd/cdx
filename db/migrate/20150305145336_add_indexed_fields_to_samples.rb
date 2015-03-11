class AddIndexedFieldsToSamples < ActiveRecord::Migration
  def change
    add_column :samples, :indexed_fields, :text
  end
end
