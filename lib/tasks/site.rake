namespace :site do
  desc "Adds a prefix to existing sites"
  task :add_prefix => :environment do
    Site.find_each { |site| site.send :compute_prefix }
    Device.find_each { |device| device.set_site_prefix; device.save! }
  end
end
