class DevicesController < ApplicationController
  layout "institutions"
  set_institution_tab :devices

  add_breadcrumb 'Institutions', :institutions_path
  before_filter do
    add_breadcrumb institution.name, institution_path(institution)
    add_breadcrumb 'Devices', institution_devices_path(institution)
  end

  expose(:institution) { current_user.visible_institutions.find(params[:institution_id]) }
  expose(:laboratories) do
    if institution_admin?
      institution.laboratories
    else
      Laboratory.with_role(:admin, current_user).where(institution_id: institution.id)
    end
  end

  expose(:devices) do
    if institution_admin?
      institution.devices
    else
      Device.with_role(:admin, current_user).where(institution_id: institution.id)
    end
  end
  expose(:device, attributes: :device_params)
  expose(:device_admin?) { current_user.has_role? :admin, device }

  before_action :check_institution_admin, only: [:create]
  before_action :check_institution_or_device_admin, only: [:update, :destroy]

  def show
    add_breadcrumb device.name, institution_device_path(institution, device)
  end

  def edit
    add_breadcrumb device.name, institution_device_path(institution, device)
  end

  def create
    respond_to do |format|
      if current_user.create(device)
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
    params.require(:device).permit(:name, :index_name, laboratory_ids: [])
  end

  def check_institution_or_device_admin
    head :unauthorized unless institution_admin? || device_admin?
  end
end
