class CreateConditions < ActiveRecord::Migration
  def change
    create_table :conditions do |t|
      t.string :name

      t.timestamps
    end

    create_table :conditions_manifests, id: false do |t|
      t.belongs_to :manifest
      t.belongs_to :condition
    end
  end
end
