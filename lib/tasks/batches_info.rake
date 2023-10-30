require 'csv'

namespace :batches_info do
  desc "Update batches information"
  task :import, [:csv_file] => :environment do |task, args|
    path = args[:csv_file] || abort("Usage: $> rake batches_info:import[path/to/file.csv] RAILS_ENV={env}")

    CSV.foreach(path, headers: true) do |row|
      batch = Batch.find_by(batch_number: row['virus_batch_number'])
      if batch
        batch.virus_shortname = row["virus_shortname"]
        batch.target_organism_name = row["target_organism_name"]
        batch.target_organism_taxonomy_id = row["target_organism_taxonomy_id"]
        batch.isolate_name = row["isolate_name"]
        batch.gisaid_id = row["gisaid_id"]
        batch.nucleotide_db_id = row["nucleotide_db_id"]
        batch.pango_lineage = row["pango_lineage"]
        batch.who_label = row["who_label"]
        batch.gisaid_clade = row["gisaid_clade"]
        batch.virus_sample_source = row["virus_sample_source"]
        batch.virus_sample_source_url = row["virus_sample_source_url"]
        batch.virus_source = row["virus_source"]
        batch.virus_location = row["virus_location"]
        batch.virus_sample_type = row["virus_sample_type"]
        batch.virus_sample_formulation = row["virus_sample_formulation"]
        batch.virus_sample_concentration = row["virus_sample_concentration"]
        batch.virus_sample_concentration_unit = row["virus_sample_concentration_unit"]
        batch.reference_gene = row["virus_sample_concentration_reference_gene"]
        batch.virus_sample_genome_equivalents = row["virus_sample_genome_equivalents"]
        batch.virus_sample_genome_equivalents_unit = row["virus_sample_genome_equivalents_unit"]
        batch.virus_sample_genome_equivalents_reference_gene = row["virus_sample_genome_equivalents_reference_gene"]
        batch.virus_preinactivation_tcid50 = row["virus_preinactivation_tcid50"]
        batch.virus_preinactivation_tcid50_unit = row["virus_preinactivation_tcid50_unit"]
        batch.virus_sample_grow_cell_line = row["virus_sample_grow_cell_line"]

        batch.save
      end
    end
  end
end
