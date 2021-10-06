class AddSiteToSamples < ActiveRecord::Migration
  def change
    add_reference :samples, :site, index: true, foreign_key: true
    add_column :samples, :site_prefix, :string
  end
end
