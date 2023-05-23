class CreateAutocompleteValues < ActiveRecord::Migration[5.0]
  def change
    create_table :autocomplete_values do |t|
      t.string :field_name
      t.string :value
      t.references :institution, null: false, foreign_key: true
      t.timestamps
    end
    add_index :autocomplete_values, [:field_name, :value, :institution_id], unique: true, name: 'autocomplete_index'
  end
end
