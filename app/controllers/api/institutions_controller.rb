class Api::InstitutionsController < ApiController
  def index
    @institutions = check_access(Institution, READ_INSTITUTION).map do |institution|
      {"uuid" => institution.uuid, "name" => institution.name}
    end

    respond_to do |format|
      format.csv do
        build_csv 'Institutions', CSVBuilder.new(@institutions, column_names: ["uuid", "name"])
        render :layout => false
      end
      format.json do
        render json: {
          total_count: @institutions.size,
          institutions: @institutions
        }
      end
    end
  end
end
