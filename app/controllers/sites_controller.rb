class SitesController < ApplicationController
  set_institution_tab :sites
  before_filter do
    head :forbidden unless has_access_to_sites_index?
  end

  def index
    @sites = check_access(Site.within(@navigation_context.entity), READ_SITE)
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_SITE)

    @sites.preload_locations!
  end

  def new
    @site = Site.new
    @sites = check_access(Site, READ_SITE).within(@navigation_context.institution)
    @site.parent = @navigation_context.site
    prepare_for_institution_and_authorize(@site, CREATE_INSTITUTION_SITE)
  end

  # POST /sites
  # POST /sites.json
  def create
    @institution = @navigation_context.institution
    return unless authorize_resource(@institution, CREATE_INSTITUTION_SITE)

    @site = @institution.sites.new(site_params)
    @sites = check_access(Site, READ_SITE)

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
    @can_be_deleted = @site.devices.empty?
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

  def dependencies
    site = Site.find(params[:id])
    @sites = check_access(site.children, READ_SITE)
    @sites_to_edit = check_access(site.children, UPDATE_SITE).pluck(:id)
    @sites.preload_locations!
    render layout: false
  end

  private

  def site_params
    if params[:site] && (params[:site][:lat].blank? || params[:site][:lng].blank?) && !params[:site][:location_geoid].blank?
      location_details = Location.details(params[:site][:location_geoid]).first
      params[:site][:lat] = location_details.try(:lat)
      params[:site][:lng] = location_details.try(:lng)
    end

    params.require(:site).permit(:name, :address, :city, :state, :zip_code, :country, :region, :lat, :lng, :location_geoid, :parent_id, :sample_id_reset_policy, :main_phone_number, :email_address)
  end
end
