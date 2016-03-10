class AddKeyToRoles < ActiveRecord::Migration
  def change
    add_column :roles, :key, :string
  end
end
