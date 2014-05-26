class CreatePolicies < ActiveRecord::Migration
  def change
    create_table :policies do |t|
      t.integer :user_id
      t.integer :granter_id
      t.text :definition
      t.boolean :delegable

      t.timestamps
    end
  end
end
