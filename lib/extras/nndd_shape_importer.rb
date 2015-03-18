#
# Converts a GeoJSON to a TopoJSON with the information needed to
# draw map charts in Notifiable Diseases.
#
# This process needs the following external programs (which can be
# installed via npm):
#   - topojson
#   - mapshaper
#
# Since NNDD uses a single TopoJSON file for each administrative level,
# we need to know which shapes belong to each level. This is currently
# done with a simple name convention: input files are assumed to be of
# the form "$(description)$(level).json".
#
# Shapes downloaded from GADM already follow this convention.
#
class NNDDShapeImporter

  def initialize(filenames)
    @filenames = filenames
    @levels = (0..9).to_a
  end

  def import!
    check_dependencies
    setup_output_dirs

    @filenames.each do |geojson_path|
      Rails.logger.info "\n---- Processing #{geojson_path}"

      Rails.logger.info "Adding metadata to geojson"
      output1 = add_metadata geojson_path

      Rails.logger.info "Converting to topojson"
      output2 = convert_to_topojson output1

      Rails.logger.info "Adding parent locations references"
      add_metadata_to_topojson output2
    end

    Rails.logger.info "\n\nCombining topojson files by level"
    combine_topojsons

    Rails.logger.info "\nDone!"
  end

  private

  def check_dependencies
    @topojson_executable  = ENV['TOPOJSON'].presence || "topojson"
    check_dependency @topojson_executable, "topojson"

    @mapshaper_executable = ENV['MAPSHAPER'].presence || "mapshaper"
    check_dependency @mapshaper_executable, "mapshaper"
  end

  def check_dependency executable, name
    present = system "#{executable} --version &> /dev/null"
    if not present
      raise "#{name} executable could not be found. If it is not in your PATH you need to define the #{name.upcase} environment variable"
    end
  end

  def setup_output_dirs
    @final_output_dir = "#{Rails.root}/public/polygons"

    @out_dir_1 = Dir.mktmpdir("nndd-geojson-with-metadata")
    @out_dir_2 = Dir.mktmpdir("nndd-topojson")
    @out_dir_3 = Dir.mktmpdir("nndd-topojson-with-metadata")

    Rails.logger.debug "Intermediate files will be saved in the following directories:\n"\
                       " - #{@out_dir_1}\n"\
                       " - #{@out_dir_2}\n"\
                       " - #{@out_dir_3}\n"

    Rails.logger.info "Result topojsons will be saved to #{@final_output_dir}"
  end

  def add_metadata input_path
    output_path = File.join @out_dir_1, Pathname.new(input_path).basename

    geojson = JSON.parse(File.read(input_path, external_encoding: "utf-8"))
    features = geojson["features"]

    features.each do |feature|
      props = feature["properties"]
      new_id = []

      id_fields = @levels.map {|l| "ID_#{l}" }
      id_fields.each do |id_field|
        new_id << props[id_field] if props.has_key? id_field
      end
      id = new_id.join "_"

      props["ID"] = id
      props["NAME"] = Location.where(geo_id: id).first.name
    end

    File.new(output_path, 'w').write(geojson.to_json)
    return output_path
  end

  def convert_to_topojson input_path
    output_path = File.join @out_dir_2, Pathname.new(input_path).basename
    system "#{@topojson_executable} \"#{input_path}\" -o \"#{output_path}\" --id-property ID --properties"
    return output_path
  end

  def add_metadata_to_topojson input_path
    def parent_id loc_id
      parts = loc_id.split "_"
      parts[0..-2].join "_"
    end

    output_path = File.join @out_dir_3, Pathname.new(input_path).basename
    topojson = JSON.parse(File.read(input_path, external_encoding: 'utf-8'))
    geometries = topojson["objects"].values.first["geometries"]
    geometries.each do |geometry|
      geometry["properties"] = {
        ID: geometry["id"],
        PARENT_ID: parent_id(geometry["id"]),
        NAME: geometry["properties"]["NAME"]
      }
    end

    File.new(output_path, 'w').write(topojson.to_json)
  end

  def combine_topojsons
    (0..9).each do |level|
      input_files = File.join @out_dir_3, "*#{level}.json"
      final_file  = File.join @final_output_dir, "level-#{level}.topo.json"

      if not Dir.glob(input_files).empty?
        system "#{@mapshaper_executable} combine-files #{input_files} -o #{final_file} format=topojson"
      end
    end
  end

end
