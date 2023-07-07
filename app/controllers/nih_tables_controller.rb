class NihTablesController < ApplicationController
  def show
    @samples_report = SamplesReport.find(params[:id])
    return unless authorize_resource(@samples_report, READ_SAMPLES_REPORT)
    
    zip_data = create_zip_file
    send_data zip_data.read, type: 'application/zip', filename: "#{@samples_report.name}_nih_tables.zip"
  end
  
  private
  
  def create_zip_file
    purpose = @samples_report.samples[0].box.purpose

    zip_stream = Zip::OutputStream.write_buffer do |stream|
      # Read public/templates/Instructions.txt contents and write to zip
      stream.put_next_entry('Instructions.txt')
      stream.write(File.read(Rails.root.join('public/templates/Instructions.txt')))

      add_nih_table('samples', stream)
      add_nih_table('results', stream)

      if purpose == "LOD"
        #add_nih_table('lod', stream)
      elsif purpose == "Challenge"
        #add_nih_table('challenge', stream)
      end
    end
    zip_stream.rewind
    zip_stream
  end

  def add_nih_table(table_name, stream)
    stream.put_next_entry("#{@samples_report.name}_#{table_name}.csv")
    stream.write(render_to_string('samples_reports/nih_'+table_name, formats: :csv))
  end
end