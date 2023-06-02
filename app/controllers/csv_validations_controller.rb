class CsvValidationsController < ApplicationController
  def create
    uploaded_file = params[:csv_file]
    if uploaded_file.content_type == "text/csv"
      csv_text = uploaded_file.read
      institution = @navigation_context.institution
      csv_table = CSV.parse(csv_text, headers: true)

      unless csv_table.headers == ["Batch", "Concentration", "Distractor", "Instructions"]
        render_invalid_format
        return
      end

      batch_values = csv_table.map { |row| row["Batch"] }
      found_batches = institution.batches.where(batch_number: batch_values).pluck(:batch_number)
      not_found_batches = (batch_values - found_batches).uniq

      render json: { found_batches: found_batches,
                     not_found_batches: not_found_batches,
                     samples_nbr: csv_table.size,
                     error_message: "" }
    else
      render_invalid_format
    end
  end

  private

  def render_invalid_format
    render json: { found_batches: [],
                   not_found_batches: [],
                   samples_nbr: 0, 
                   error_message: "Invalid file format." }
  end

end
