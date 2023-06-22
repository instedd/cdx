class NihTablesController < ApplicationController
  def show
    samples_report = SamplesReport.find(params[:id])
    return unless authorize_resource(samples_report, READ_SAMPLES_REPORT)
    
    purpose = samples_report.samples[0].box.purpose
    zip_file = create_zip_file(samples_report.name)
  
    if purpose == "LOD"
    add_lod_table(zip_file)
    elsif purpose == "Challenge"
    add_challenge_table(zip_file)
    end
  
    zip_file.close
  
    send_zip_file(zip_file, samples_report.name)
  end
  
  private
  
  def create_zip_file(filename)
    zip_file = Tempfile.new("#{filename}_nih_tables.zip")
    Zip::File.open(zip_file.path, Zip::File::CREATE) do |zip|
    zip.add("Instructions.txt", Rails.root.join('public/templates/Instructions.txt'))
    end
    zip_file
  end
  
  def add_lod_table(zip_file)
    # TODO: Add the LOD table to the zip file
  end
  
  def add_challenge_table(zip_file)
    # TODO: Add the Challenge table to the zip file
  end
  
  def send_zip_file(zip_file, filename)
    send_file zip_file.path, type: 'application/zip', filename: "#{filename}_nih_tables.zip"
  end
end