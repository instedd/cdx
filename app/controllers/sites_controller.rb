class SitesController < ApplicationController
  set_institution_tab :sites
  before_filter do
    head :forbidden unless has_access_to_sites_index?
  end

  #================================================================================================================
  def index
    @sites = check_access(Site.within(@navigation_context.entity, @navigation_context.exclude_subsites), READ_SITE)
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_SITE)
    apply_filters

    respond_to do |format|
      format.html do
        @sites = perform_pagination(@sites)
        @sites.preload_locations!
      end
      format.csv do
        @sites.preload_locations!
        filename = "Sites-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
        headers["Content-Type"] = "text/csv"
        headers["Content-disposition"] = "attachment; filename=#{filename}"
        self.response_body = build_csv
      end
    end
  end

  #================================================================================================================
  def new
    @site = Site.new
    @sites = check_access(Site, READ_SITE).within(@navigation_context.institution)
    @site.parent = @navigation_context.site
    prepare_for_institution_and_authorize(@site, CREATE_INSTITUTION_SITE)
  end

  #================================================================================================================
  # POST /sites
  # POST /sites.json
  def create
    @institution = @navigation_context.institution
    return unless authorize_resource(@institution, CREATE_INSTITUTION_SITE)

    @site = @institution.sites.new(site_params(true))
    @sites = check_access(@institution.sites, READ_SITE)

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

  #================================================================================================================
  def edit
    @site = Site.with_deleted.find(params[:id])
    return unless authorize_resource(@site, READ_SITE)

    @can_move = !@site.deleted? && has_access?(@navigation_context.institution, CREATE_INSTITUTION_SITE)
    @can_edit = !@site.deleted? && has_access?(@site, UPDATE_SITE)
    if @can_edit
      @can_delete = has_access?(@site, DELETE_SITE)
      @can_be_deleted = @site.devices.empty?
      @sites = check_access(@navigation_context.institution.sites, READ_SITE) if @can_move
    end
  end

  #================================================================================================================
  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    @site = Site.find params[:id]
    institution = @site.institution
    redirect_options = {}

    return unless authorize_resource(@site, UPDATE_SITE)

    @can_move = has_access?(institution, CREATE_INSTITUTION_SITE)

    respond_to do |format|
      update_or_save = false

      if site_params(@can_move).has_key?(:parent_id) && site_params(@can_move)[:parent_id].to_i != @site.parent_id
        new_site = institution.sites.new(site_params(true))
        begin
          Site.transaction do
            new_site.save!
            @site.devices.each do |device|
              device.site = new_site
              device.save!
            end
            @site.devices.clear

            @site.destroy
            update_or_save = true
            redirect_options = { context: new_site.uuid } if @navigation_context.entity.uuid == @site.uuid
          end
        rescue => e
          update_or_save = false
          # propagate errors from site to be created to original site
          new_site.errors.each do |k, m|
            @site.errors.add(k, m)
          end
          # mimic that attributes have been edited in the original site
          @site.assign_attributes(site_params)
        end
      else
        update_or_save = @site.update(site_params)
      end

      if update_or_save
        format.html { redirect_to sites_path(redirect_options), notice: 'Site was successfully updated.' }
        format.json { head :no_content }
      else
        @sites = check_access(institution.sites, READ_SITE) if @can_move

        format.html { render action: 'edit' }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  #================================================================================================================
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

  #================================================================================================================
  def devices
    @site = Site.find(params[:id])
    return unless authorize_resource(@site, READ_SITE)

    @devices_to_edit = check_access(@site.devices, UPDATE_DEVICE).pluck(:id)

    render layout: false
  end

  #================================================================================================================
  def tests
    @site = Site.find(params[:id])
    return unless authorize_resource(@site, READ_SITE)

    render layout: false
  end

  private

  #================================================================================================================
  def site_params(with_parent_id = false)
    if params[:site] && (params[:site][:lat].blank? || params[:site][:lng].blank?) && !params[:site][:location_geoid].blank?
      location_details = Location.details(params[:site][:location_geoid]).first
      params[:site][:lat] = location_details.try(:lat)
      params[:site][:lng] = location_details.try(:lng)
    end

    allowed_params = [:name, :address, :city, :state, :zip_code, :country, :region, :lat, :lng, :location_geoid, :sample_id_reset_policy, :main_phone_number, :email_address, :allows_manual_entry]
    allowed_params << :parent_id if with_parent_id

    params.require(:site).permit(*allowed_params)
  end

  #================================================================================================================
  def apply_filters
    @sites = @sites.where("location_geoid LIKE concat(?, '%')", params[:location]) if params[:location].present?
    @sites = @sites.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
  end

  #================================================================================================================
  def build_csv
    CSV.generate do |csv|
      csv << ["Name", "Location"]
      @sites.each do |s|
        csv << [s.name, s.location.try(:name)]
      end
    end
  end
end
