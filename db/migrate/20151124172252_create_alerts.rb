class CreateAlerts < ActiveRecord::Migration
  def change
    create_table :alerts do |t|
      t.references :user, index: true
      t.string :name
      t.string :description
      t.boolean :enabled, default: true
      t.integer :receipients, default: 0
      t.datetime :last_alert 
      t.timestamps
    end
  end
end
