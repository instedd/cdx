class CsvValidationsController < ApplicationController
  def create
    uploaded_file = params[:csv_file]
    if uploaded_file.content_type == "text/csv"
      csv_text = uploaded_file.read
      institution = @navigation_context.institution
      csv_table = CSV.parse(csv_text, headers: true)
      batch_values = csv_table.map { |row| row["Batch"] }
      found_batches = institution.batches.where(batch_number: batch_values).pluck(:batch_values)
      not_found_batches = (batch_values - found_batches).uniq

      render json: { found_batches: found_batches,
                    not_found_batches: not_found_batches,
                    batches_nbr: batch_values.size }
    else
      render json: { error: "Invalid file format. Please upload a CSV file." }, status: :unprocessable_entity
    end
  end
end
