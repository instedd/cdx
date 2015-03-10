require 'cdx_sync'
namespace :csv do
  desc "Load all csv files on the sync folder"
  task :load => :environment do |task, args|
    DeviceEventImporter.new.import_from CDXSync::SyncDirectory.new
  end
end
