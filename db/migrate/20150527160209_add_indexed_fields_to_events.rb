class AddIndexedFieldsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :indexed_fields, :text
  end
end
