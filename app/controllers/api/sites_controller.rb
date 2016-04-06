class Api::SitesController < ApiController
  
  #================================================================================================================
  def index
    @sites = if params[:institution_uuid]
      Institution.find_by_uuid(params[:institution_uuid]).sites
    else
      Site.all
    end

    @uuids = Set.new
    @sites = check_access(@sites, READ_SITE).map do |site|
      @uuids << site.uuid

      {"uuid" => site.uuid, "name" => site.name, "location" => site.location_geoid, "parent_uuid" => site.parent.try(:uuid), "institution_uuid" => site.institution.uuid }
    end

    @sites.each do |site|
      site["parent_uuid"] = nil unless @uuids.include?(site["parent_uuid"])
    end

    # do some ordering here (dave)
    @sites.sort! {|a,b| a['name']<=>b['name']}

    respond_to do |format|
      format.csv do
        build_csv 'Sites', CSVBuilder.new(@sites, column_names: ["uuid", "name", "location", "parent_uuid", "institution_uuid"])
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
