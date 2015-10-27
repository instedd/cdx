class CreateProspects < ActiveRecord::Migration
  def change
    create_table :prospects do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :contact_number
      t.string :uuid
      t.string :type
      t.timestamps
    end
    add_index :prospects, :email
    add_index :prospects, :uuid
    add_index :prospects, :type
  end
end
