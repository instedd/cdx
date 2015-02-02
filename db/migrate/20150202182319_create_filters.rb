class CreateFilters < ActiveRecord::Migration
  def change
    create_table :filters do |t|
      t.references :user, index: true
      t.string :name
      t.text :params

      t.timestamps
    end
  end
end
