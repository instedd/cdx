class AddParentIdAndPrefixToSites < ActiveRecord::Migration
  def change
    add_column :sites, :parent_id, :integer
    add_column :sites, :prefix, :string
  end
end
