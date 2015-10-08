class Api::SitesController < ApiController
  def index
    @sites = if params[:institution_uuid]
      Institution.find_by_uuid(params[:institution_uuid]).sites
    else
      Site.all
    end

    @sites = check_access(@sites, READ_SITE).map do |site|
      {"uuid" => site.uuid, "name" => site.name, "location" => site.location_geoid}
    end

    respond_to do |format|
      format.csv do
        build_csv 'Sites', CSVBuilder.new(@sites, column_names: ["uuid", "name", "location"])
        render :layout => false
      end
      format.json do
        render_json({
          total_count: @sites.size,
          sites: @sites
        })
      end
    end
  end
end
