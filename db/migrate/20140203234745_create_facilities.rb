class CreateFacilities < ActiveRecord::Migration
  def change
    create_table :facilities do |t|
      t.string :name
      t.references :work_group, index: true
      t.string :index_name

      t.timestamps
    end
  end
end
