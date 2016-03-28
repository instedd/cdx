class AddSidebarOpenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :sidebar_open, :boolean, default: true
  end
end
