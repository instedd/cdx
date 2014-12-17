namespace :csv do
  desc "Load all csv files on the default folder"
  task :load => :environment do |task, args|
    Dir.glob(File.join(Settings.import_directory, "*.csv")).each do |file_name|
      File.open(file_name) do |file|
        # File name follows the pattern: "device_key-yyyymmdd-mmss.csv"
        CSVEventParser.new.load_for_device file, file_name[0..-("-yyyymmdd-mmss.csv".length + 1)]
      end
    end
  end
end
