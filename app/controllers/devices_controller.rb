class DevicesController < ApplicationController
  layout "institutions"
  set_institution_tab :devices

  add_breadcrumb 'Institutions', :institutions_path
  before_filter do
    add_breadcrumb institution.name, institution_path(institution)
    add_breadcrumb 'Devices', institution_devices_path(institution)
  end

  expose(:institution) { current_user.institutions.find(params[:institution_id]) }
  expose(:laboratories) { institution.laboratories }

  expose(:devices) { institution.devices }
  expose(:device, attributes: :device_params)

  def show
    add_breadcrumb device.name, institution_device_path(institution, device)
  end

  def edit
    add_breadcrumb device.name, institution_device_path(institution, device)
  end

  def create
    respond_to do |format|
      if device.save
        format.html { redirect_to institution_devices_path(institution), notice: 'Device was successfully created.' }
        format.json { render action: 'show', status: :created, location: device }
      else
        format.html { render action: 'new' }
        format.json { render json: device.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if device.update(device_params)
        format.html { redirect_to institution_devices_path(institution), notice: 'Device was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: device.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    device.destroy
    respond_to do |format|
      format.html { redirect_to institution_devices_url(institution) }
      format.json { head :no_content }
    end
  end

  def regenerate_key
    device.set_key
    respond_to do |format|
      if device.save
        format.html { redirect_to edit_institution_device_path(institution, device), notice: 'Key updated' }
        format.json { render action: 'show', location: device }
      else
        format.html { render action: 'edit' }
        format.json { render json: device.errors, status: :unprocessable_entity }
      end
    end
  end


  private

  def device_params
    params.require(:device).permit(:name, :laboratory_id, :index_name)
  end
end
