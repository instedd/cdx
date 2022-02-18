class AssayFilesController < ApplicationController
  def create
    assay_files = params.require(:assay_files)
    assay_files_data = {}

    begin
      AssayFile.transaction do
        assay_files.each do |index, file|
          assay_file = AssayFile.create!(picture: file)
          assay_files_data[assay_file.picture_file_name] = assay_file.id
        end
      end
    rescue => exception
      Raven.capture_exception(exception)
      render json: {status: :error}, status: :internal_server_error
    else
      render json: {status: :ok, assay_files_data: assay_files_data}
    end
  end
end
