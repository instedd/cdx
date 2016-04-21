class AddSampleIdentifierGenerationToSites < ActiveRecord::Migration
  def change
    add_column :sites, :last_sample_identifier_entity_id, :string
    add_column :sites, :last_sample_identifier_date, :date
  end
end
