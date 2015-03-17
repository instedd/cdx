require 'geojson_import'

desc "Imports all locations from /etc/shapes"
task :geo do
  Rake::Task['geo:all'].invoke
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

  desc "Validates if the center of all locations is contained within their polygon"
  task :validate => :logger do
    Geojson::Indexer.new.validate_center(Location.includes(:shape).all)
  end

  desc "Converts downloaded shapes to topojson format and exposes them for Notifiable Diseases"
  task :nndd => :logger do
    filenames = Dir["#{Rails.root}/etc/shapes/**/*.json"]
    NNDDShapeImporter.new(filenames).import!
  end

  task :logger => :environment do
    if Rails.env.development?
      logger       = Logger.new(STDOUT)
      logger.level = Logger::INFO
      Rails.logger = logger
    end
  end

end
