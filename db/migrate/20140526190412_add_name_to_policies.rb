class AddNameToPolicies < ActiveRecord::Migration
  def change
    add_column :policies, :name, :string
  end
end
