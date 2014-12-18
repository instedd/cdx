namespace :csv do
  desc "Load all csv files on the default folder"
  task :load => :environment do |task, args|
    CSVEventParser.new.import_from Settings.import_directory
  end
end
