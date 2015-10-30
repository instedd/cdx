class SitesController < ApplicationController
  set_institution_tab :sites
  before_filter :load_institutions
  before_filter do
    @main_column_width = 6 unless params[:action] == 'index'
  end

  def index
    return head :forbidden unless can_index_sites?

    @sites = check_access(Site, READ_SITE)
    @institutions = check_access(Institution, READ_INSTITUTION)
    @can_create = has_access?(@institutions, CREATE_INSTITUTION_SITE)

    if (institution_id = params[:institution].presence)
      @sites = @sites.where(institution_id: institution_id.to_i)
    end
  end

  def new
    @site = Site.new
    prepare_for_institution_and_authorize(@site, CREATE_INSTITUTION_SITE)
  end

  # POST /sites
  # POST /sites.json
  def create
    @institution = Institution.find params[:site][:institution_id]
    return unless authorize_resource(@institution, CREATE_INSTITUTION_SITE)

    @site = @institution.sites.new(site_params)

    respond_to do |format|
      if @site.save
        format.html { redirect_to sites_path, notice: 'Site was successfully created.' }
        format.json { render action: 'show', status: :created, location: @site }
      else
        format.html { render action: 'new' }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @site = Site.find(params[:id])
    return unless authorize_resource(@site, READ_SITE)

    @can_edit = has_access?(@site, UPDATE_SITE)
    @show_institution = show_institution?(Policy::Actions::READ_SITE, Site)
  end

  def edit
    @site = Site.find(params[:id])
    return unless authorize_resource(@site, UPDATE_SITE)

    @can_delete = has_access?(@site, DELETE_SITE)
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    @site = Site.find params[:id]
    return unless authorize_resource(@site, UPDATE_SITE)

    respond_to do |format|
      if @site.update(site_params)
        format.html { redirect_to sites_path, notice: 'Site was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sites/1
  # DELETE /sites/1.json
  def destroy
    @site = Site.find params[:id]
    return unless authorize_resource(@site, DELETE_SITE)

    @site.destroy

    respond_to do |format|
      format.html { redirect_to sites_path, notice: 'Site was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  def devices
    @site = Site.find(params[:id])
    return unless authorize_resource(@site, READ_SITE)

    @devices_to_edit = check_access(@site.devices, UPDATE_DEVICE).pluck(:id)

    render layout: false
  end

  def tests
    @site = Site.find(params[:id])
    return unless authorize_resource(@site, READ_SITE)

    render layout: false
  end

  private

  def load_institutions
    @institutions = check_access(Institution, CREATE_INSTITUTION_SITE)
  end

  def site_params
    location_details = Location.details(params[:site][:location_geoid]).first
    if location_details
      params[:site][:lat] = location_details.lat
      params[:site][:lng] = location_details.lng
    end
    params.require(:site).permit(:name, :address, :city, :state, :zip_code, :country, :region, :lat, :lng, :location_geoid)
  end
end
