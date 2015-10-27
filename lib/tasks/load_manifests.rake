require 'cdx_sync'
namespace :manifests do
  desc "Load all csv files on the sync folder"
  task :load => :environment do |task, args|
    Dir.glob(File.join(Rails.root, 'db', 'seeds', 'manifests', '*.json')) do |path|
      device_model = DeviceModel.find_or_create_by! name: File.basename(path, '_manifest.json').titleize
      device_model.update manifest_attributes: {definition: IO.read(path)}
      device_model.tap(&:set_published_at).save!
    end
  end
end
