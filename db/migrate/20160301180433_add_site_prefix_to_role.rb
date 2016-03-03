class AddSitePrefixToRole < ActiveRecord::Migration
  def change
    add_column :roles, :site_prefix, :string
  end
end
