class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.references :institution, null: false
      t.references :site
      t.references :policy, null: false

      t.timestamps
    end

    create_table :roles_users, id: false do |t|
      t.belongs_to :role
      t.belongs_to :user
    end
  end
end
