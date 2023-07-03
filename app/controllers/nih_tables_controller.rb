class NihTablesController < ApplicationController
  def show
    @samples_report = SamplesReport.find(params[:id])
    return unless authorize_resource(@samples_report, READ_SAMPLES_REPORT)
    
    zip_file = create_zip_file
    zip_file.close
  
    send_zip_file(zip_file)
  end
  
  private
  
  def create_zip_file
    purpose = @samples_report.samples[0].box.purpose
    zip_file = Tempfile.new("#{@samples_report.name}_nih_tables.zip")
    Zip::File.open(zip_file.path, Zip::File::CREATE) do |zip|
      zip.add("Instructions.txt", Rails.root.join('public/templates/Instructions.txt'))
      add_nih_table('samples', zip)
      add_nih_table('results', zip)

      if purpose == "LOD"
        #add_nih_table('lod', zip)
      elsif purpose == "Challenge"
        #add_nih_table('challenge', zip)
      end
    end
    zip_file
  end

  def add_nih_table(table_name, zip_file)
    csv_file = Tempfile.new("#{@samples_report.name}_#{table_name}.csv")
    
    csv_file.write(
      render_to_string('samples_reports/nih_'+table_name, formats: :csv)
    )
    csv_file.close
    zip_file.add("#{@samples_report.name}_#{table_name}.csv", csv_file.path)
  end
  
  def send_zip_file(zip_file)
    send_file zip_file.path, type: 'application/zip', filename: "#{@samples_report.name}_nih_tables.zip"
  end
end