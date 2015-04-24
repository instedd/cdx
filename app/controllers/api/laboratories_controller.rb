class Api::LaboratoriesController < ApiController
  def index
    @laboratories = if params[:institution_id]
      Institution.find(params[:institution_id]).laboratories
    else
      Laboratory.all
    end

    @laboratories = check_access(@laboratories, READ_LABORATORY).map do |lab|
      {id: lab.id, name: lab.name, location: lab.location_geoid}
    end

    respond_to do |format|
      format.csv do
        build_csv 'Laboratories', CSVBuilder.new(@laboratories, column_names: ["id", "name", "location"])
        render :layout => false
      end
      format.json do
        render_json({
          total_count: @laboratories.size,
          laboratories: @laboratories
        })
      end
    end
  end
end
