class AddLastNavigationContextToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_navigation_context, :string
  end
end
