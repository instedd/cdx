class AutocompletesController < ApplicationController

  def index
    @institution = Institution.find(params[:institution_id])
    @unique_values = unique_values_for(params[:field_name], params[:query])
    render json: @unique_values.map { |option| { value: option, label: option } }
  end

  private

  def unique_values_for(field_name, query)
    batch_values = check_access(@institution.batches, READ_BATCH).collect(&field_name.to_sym).uniq
    sample_values = check_access(@institution.samples, READ_BATCH).collect(&field_name.to_sym).uniq
    (batch_values + sample_values).uniq.compact.select { |value| value.to_s.downcase.include?(query.downcase) }.split(',')
  end
end
