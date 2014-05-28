class DevicesController < ApplicationController
  layout "institutions"
  set_institution_tab :devices

  add_breadcrumb 'Institutions', :institutions_path

  before_filter :load_institution

  before_filter do
    add_breadcrumb @institution.name, institution_path(@institution)
    add_breadcrumb 'Devices', institution_devices_path(@institution)
  end

  def index
    @devices = authorize_resource(@institution.devices, Policy::READ_DEVICE)
  end

  def new
    @device = @institution.devices.new
    return unless authorize_resource(@device, Policy::CREATE_DEVICE)
  end

  def create
    @device = @institution.devices.new(device_params)
    return unless authorize_resource(@device, Policy::CREATE_DEVICE)

    respond_to do |format|
      if @device.save
        format.html { redirect_to institution_devices_path(@institution), notice: 'Device was successfully created.' }
        format.json { render action: 'show', status: :created, location: @device }
      else
        format.html { render action: 'new' }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @device = @institution.devices.find params[:id]
    return unless authorize_resource(@device, Policy::UPDATE_DEVICE)

    add_breadcrumb @device.name, institution_device_path(@institution, @device)
  end

  def update
    @device = @institution.devices.find params[:id]
    return unless authorize_resource(@device, Policy::UPDATE_DEVICE)

    respond_to do |format|
      if @device.update(device_params)
        format.html { redirect_to institution_devices_path(@institution), notice: 'Device was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @device = @institution.devices.find params[:id]
    return unless authorize_resource(@device, Policy::DELETE_DEVICE)

    @device.destroy

    respond_to do |format|
      format.html { redirect_to institution_devices_url(@institution) }
      format.json { head :no_content }
    end
  end

  def regenerate_key
    @device = @institution.devices.find params[:id]
    return unless authorize_resource(@device, Policy::REGENERATE_DEVICE_KEY)

    @device.set_key

    respond_to do |format|
      if @device.save
        format.html { redirect_to edit_institution_device_path(@institution, @device), notice: 'Key updated' }
        format.json { render action: 'show', location: @device }
      else
        format.html { render action: 'edit' }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_institution
    @institution = Institution.find params[:institution_id]
    authorize_resource(@institution, Policy::READ_INSTITUTION)
  end

  def device_params
    params.require(:device).permit(:name, :index_name, :device_model_id, laboratory_ids: [])
  end
end
