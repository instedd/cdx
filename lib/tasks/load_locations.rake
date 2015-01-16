require 'cdx_sync'
namespace :locations do
  desc "Load all csv files on the sync folder"
  task :load => :environment do |task, args|
    load "#{Rails.root}/db/seeds/locations.rb"
  end
end
