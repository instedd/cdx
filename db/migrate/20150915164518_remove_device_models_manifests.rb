class RemoveDeviceModelsManifests < ActiveRecord::Migration
  class Manifest < ActiveRecord::Base
    serialize :definition, JSON
    has_and_belongs_to_many :device_models
    belongs_to :device_model
  end
  def up
    add_column :manifests, :device_model_id, :integer

    Manifest.find_each do |manifest|
      manifest.device_model = manifest.device_models.first
      manifest.save(validate: false)
    end

    drop_table :device_models_manifests
  end

  def down
    create_table "device_models_manifests", id: false, force: :cascade do |t|
      t.integer "manifest_id"
      t.integer "device_model_id"
    end

    Manifest.find_each do |manifest|
      manifest.device_models = [manifest.device_model]
      manifest.save(validate: false)
    end

    remove_column :manifests, :device_model_id
  end
end
