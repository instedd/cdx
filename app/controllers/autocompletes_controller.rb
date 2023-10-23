class AutocompletesController < ApplicationController
  def index
    permitted_attributes = [
      'virus_shortname',
      'reference_gene',
      'target_organism_name',
      'target_organism_taxonomy_id',
      'pango_lineage',
      'who_label',
      'gisaid_id',
      'gisaid_clade',
      'nucleotide_db_id',
      'virus_sample_source',
      'virus_sample_source_url',
      'virus_source',
      'virus_location',
      'virus_sample_type',
      'virus_sample_formulation',
      'virus_sample_concentration',
      'virus_sample_concentration_unit',
      'virus_sample_genome_equivalents',
      'virus_sample_genome_equivalents_unit',
      'virus_sample_genome_equivalents_reference_gene',
      'virus_preinactivation_tcid50',
      'virus_preinactivation_tcid50_unit',
      'virus_sample_grow_cell_line'
    ]

    @institution = Institution.find(params[:institution_id])

    unless params[:field_name].in?(permitted_attributes)
      raise ArgumentError, "Invalid field_name: #{params[:field_name]}"
    end

    @unique_values = unique_values_for(params[:field_name], params[:query])
    render json: @unique_values.map { |option| { value: option, label: option } }
  end

  private

  def unique_values_for(field_name, query)
    values = Set.new
    matcher = Regexp.new(Regexp.escape(query), Regexp::IGNORECASE)

    check_access(@institution.batches, READ_BATCH).select(:id, :core_fields, :uuid, :custom_fields).find_each do |batch|
      value = batch.send(field_name)
      values << value if value&.match?(matcher)
    end

    values.to_a
  end
end
