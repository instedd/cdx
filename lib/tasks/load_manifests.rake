require 'cdx_sync'
namespace :manifests do
  desc "Load all csv files on the sync folder"
  task :load => :environment do |task, args|
    Dir.glob(File.join(Rails.root, 'db', 'seeds', 'manifests', '*.json')) do |path|
      DeviceModel.create!(name: File.basename(path, '_manifest.json').titleize, manifest_attributes: {definition: IO.read(path)} )
    end
  end
end
