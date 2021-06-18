class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.text :description
      t.references :user, index: true
      t.references :laboratory_sample, index: true

      t.timestamps null: false
    end
  end
end

