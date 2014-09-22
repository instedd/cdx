class ChangeManifestVersionFromIntegerToString < ActiveRecord::Migration
  def change
    change_column :manifests, :version, :string
  end
end
