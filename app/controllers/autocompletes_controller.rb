class AutocompletesController < ApplicationController
  def index
    permitted_attributes = %w[reference_gene target_organism_taxonomy_id pango_lineage who_label]
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
      value = batch.try(field_name)
      values << value if value&.match?(matcher)
    end

    check_access(@institution.samples, READ_SAMPLE).select(:id, :core_fields, :custom_fields).find_each do |sample|
      value = sample.try(field_name)
      values << value if value&.match?(matcher)
    end

    values.to_a
  end
end
