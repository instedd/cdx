namespace :site do
  desc "Adds a prefix to existing sites and related entities"
  task :add_prefix => :environment do
    Site.find_each do |site|
      begin
        site.send :compute_prefix
      rescue => e
        puts "Error Site (id=#{site.id}) #{e.message}"
      end
    end

    # classes that includes SiteContained
    [Device, Encounter, TestResult, Patient].each do |type|
      type.find_each do |record|
        begin
          record.set_site_prefix
          record.save!
        rescue => e
          puts "Error #{type} (id=#{record.id}) #{e.message}"
        end
      end
    end
  end
end
