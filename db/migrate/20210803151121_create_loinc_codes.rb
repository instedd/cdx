class CreateLoincCodes < ActiveRecord::Migration
  def change
    create_table :loinc_codes do |t|
      t.string :loinc_number
      t.string :component
    end

    add_index :loinc_codes, :loinc_number
    add_index :loinc_codes, :component
  end
end
