class AssayFilesController < ApplicationController
  def create
    assay_files = params.require(:assay_files)
    assay_files_data = {}
    AssayFile.transaction do
      begin
        assay_files.each do |index, file|
          assay_file = AssayFile.new(picture: file)
          assay_file.save!
          assay_files_data[assay_file.picture_file_name] = assay_file.id
        end
        render json: {status: :ok, assay_files_data: assay_files_data}
      rescue
        render json: {status: :error}
      end
    end
  end
end
