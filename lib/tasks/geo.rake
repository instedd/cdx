require 'geojson_import'

desc "Imports all locations from /etc/shapes and regenerates the index"
task :geo do
  Rake::Task['Geojson:all'].invoke
end

namespace :geo do

  desc "Downloads all locations file into the shapefiles folder"
  task :download => :logger do
    filenames = Settings.remote_shapefiles
    Geojson::Downloader.new(filenames).download!
  end

  desc "Imports all locations from the shapefiles folder"
  task :import => :logger do
    filenames = Dir["#{Rails.root}/etc/shapes/**/*.json"]
    Geojson::Importer.new(filenames).import!
  end

  desc "Deletes existing locations index and reindexes all locations from DB"
  task :reindex => :logger do
    Geojson::Indexer.new.reindex_all!
  end

  desc "Validates if the center of all locations is contained within their polygon"
  task :validate => :logger do
    Geojson::Indexer.new.validate_center(Location.includes(:shape).all)
  end

  desc "Downloads all locations into /etc/shapes and regenerates the index"
  task :all => :logger do
    filenames = Settings.remote_shapefiles
    downloaded = Geojson::Downloader.new(filenames).download!

    if downloaded.empty?
      Rails.logger.info("No new files downloaded.")
    else
      Rails.logger.info("Downloaded: #{downloaded.join('; ')}")
      Geojson::Importer.new(downloaded).import!
      Geojson::Indexer.new.reindex_all!
    end
  end

  task :logger => :environment do
    if Rails.env.development?
      logger       = Logger.new(STDOUT)
      logger.level = Logger::INFO
      Rails.logger = logger
    end
  end

end
