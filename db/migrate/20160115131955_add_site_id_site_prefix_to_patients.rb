class AddSiteIdSitePrefixToPatients < ActiveRecord::Migration
  def change
    add_reference :patients, :site, index: true, foreign_key: true
    add_column :patients, :site_prefix, :string
  end
end
