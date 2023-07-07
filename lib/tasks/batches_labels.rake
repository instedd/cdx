require 'csv'

namespace :batches_labels do
  desc "Update batches label fields"
  task :import, [:csv_file] => :environment do |task, args|
    path = args[:csv_file] || abort("Usage: $> rake batches_labels:import[path/to/file.csv] RAILS_ENV={env}")

    CSV.foreach(path, headers: true) do |row|
      batch = Batch.find_by(batch_number: row['batch_number'])
      if batch
        batch.reference_gene = row['reference_gene']
        batch.target_organism_taxonomy_id = row['target_organism_taxonomy_id']
        batch.pango_lineage = row['pango_lineage']
        batch.who_label = row['who_label']
        batch.save
      end
    end
  end
end
