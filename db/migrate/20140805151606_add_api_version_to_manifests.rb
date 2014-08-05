class AddApiVersionToManifests < ActiveRecord::Migration
  def change
    add_column :manifests, :api_version, :string
  end
end
