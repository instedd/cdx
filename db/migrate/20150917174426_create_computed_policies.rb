class CreateComputedPolicies < ActiveRecord::Migration
  def change
    create_table :computed_policies do |t|
      t.integer :user_id
      t.boolean :allow
      t.string  :action
      t.string  :resource_type
      t.integer :resource_id,              null: true
      t.integer :condition_institution_id, null: true
      t.integer :condition_laboratory_id,  null: true
    end
  end
end
