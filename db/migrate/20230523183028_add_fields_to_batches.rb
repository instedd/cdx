class AddFieldsToBatches < ActiveRecord::Migration[5.0]
  def change
    add_column :batches, :reference_gene, :string
    add_column :batches, :target_organism_taxonomy_id, :integer
    add_column :batches, :pango_lineage, :string
    add_column :batches, :who_label, :string
  end
end
