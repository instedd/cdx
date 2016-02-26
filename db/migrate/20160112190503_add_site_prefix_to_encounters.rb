class AddSitePrefixToEncounters < ActiveRecord::Migration
  def change
    add_column :encounters, :site_prefix, :string
  end
end
