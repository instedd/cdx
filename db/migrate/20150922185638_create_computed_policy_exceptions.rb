class CreateComputedPolicyExceptions < ActiveRecord::Migration
  def change
    create_table :computed_policy_exceptions do |t|
      t.integer :computed_policy_id
      t.string  :action
      t.string  :resource_type
      t.integer :resource_id,              null: true
      t.integer :condition_institution_id, null: true
      t.integer :condition_laboratory_id,  null: true
    end
  end
end
