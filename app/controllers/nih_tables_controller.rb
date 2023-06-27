require 'csv'

class NihTablesController < ApplicationController
  def show
    samples_report = SamplesReport.find(params[:id])
    return unless authorize_resource(samples_report, READ_SAMPLES_REPORT)
    
    zip_file = create_zip_file(samples_report)
    zip_file.close
  
    send_zip_file(zip_file, samples_report.name)
  end
  
  private
  
  def create_zip_file(samples_report)
    purpose = samples_report.samples[0].box.purpose
    zip_file = Tempfile.new("#{samples_report.name}_nih_tables.zip")
    Zip::File.open(zip_file.path, Zip::File::CREATE) do |zip|
      zip.add("Instructions.txt", Rails.root.join('public/templates/Instructions.txt'))
      add_general_samples_table(samples_report, zip)
      add_general_results_table(samples_report, zip)

      if purpose == "LOD"
        add_lod_table(samples_report, zip_file)
      elsif purpose == "Challenge"
        add_challenge_table(samples_report, zip_file)
      end
    end
    zip_file
  end

  def add_general_samples_table(samples_report, zip_file)
    csv_file = Tempfile.new("#{samples_report.name}_samples.csv")
    csv_data = []
  
    csv_data << [
      'sample_id',
      'vqa_box_id',
      'sample_group',
      'sample_media',
      'sample_media_id',
      'sample_media_source',
      'sample_media_source_url',
      'sample_concentration',
      'sample_concentration_unit',
      'sample_concentration_reference_gene',
      'virus_sample_id',
      'virus_batch_number',
      'target_analyte_type',
      'target_organism_name',
      'target_organism_taxonomy_id',
      'pango_lineage',
      'who_label',
      'virus_sample_inactivation_method'
    ]
  
    samples_report.samples.each do |sample|
      batch = Batch.find_by(batch_number: sample.batch_number)
      csv_data << [
        sample.id,
        sample.box.uuid,
        "#{sample.box.purpose}-panel",
        nil,
        nil,
        nil,
        nil,
        sample.concentration,
        'copies/ml',
        batch.reference_gene,
        sample.id,
        sample.batch_number,
        'inactivated virus',
        'SARS-CoV-2',
        batch.target_organism_taxonomy_id,
        batch.pango_lineage,
        batch.who_label,
        sample.inactivation_method
      ]
    end
  
    CSV.open(csv_file.path, 'w') do |csv|
      csv_data.each do |row|
        csv << row
      end
    end
  
    zip_file.add("#{samples_report.name}_samples.csv", csv_file.path)
  end
  
  def add_general_results_table(samples_report, zip_file)
    csv_file = Tempfile.new("#{samples_report.name}_results.csv")
    csv_data = []
  
    csv_data << [
      'sample_id',
      'vqa_box_id',
      'sample_group',
      'protocol_id',
      'technology_platform',
      'assay_readout',
      'assay_readout_unit',
      'assay_readout_description'
    ]
  
    samples_report.samples.each do |sample|
      csv_data << [
        sample.id,
        sample.box.uuid,
        "#{sample.box.purpose}-panel",
        nil,
        nil,
        sample.measured_signal,
        nil,
        nil
      ]
    end
  
    CSV.open(csv_file.path, 'w') do |csv|
      csv_data.each do |row|
        csv << row
      end
    end
  
    zip_file.add("#{samples_report.name}_results.csv", csv_file.path)
  end

  def add_lod_table(samples_report, zip_file)
    # TODO: Add the LOD table to the zip file
  end
  
  def add_challenge_table(samples_report, zip_file)
    # TODO: Add the Challenge table to the zip file
  end
  
  def send_zip_file(zip_file, filename)
    send_file zip_file.path, type: 'application/zip', filename: "#{filename}_nih_tables.zip"
  end
end