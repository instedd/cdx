require 'cdx_sync'
namespace :locations do
  desc "Ensures the existance of the default 'World' location"
  task :create_default => :environment do |task, args|
    Location.find_or_create_default
  end
end
