class CreateManifests < ActiveRecord::Migration
  def change
    create_table :manifests do |t|
      t.integer :version
      t.text :definition

      t.timestamps
    end

    create_table :device_models_manifests, id: false do |t|
      t.belongs_to :manifest
      t.belongs_to :device_model
    end
  end
end
