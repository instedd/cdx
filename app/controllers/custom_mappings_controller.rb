class CustomMappingsController < ApplicationController
  layout "institutions"
  set_institution_tab :devices

  before_filter :load_institution
  before_filter :load_device

  before_filter do
    add_breadcrumb 'Institutions', :institutions_path
    add_breadcrumb @institution.name, institution_path(@institution)
    add_breadcrumb 'Devices', institution_devices_path(@institution)
    add_breadcrumb @device.name, institution_device_path(@institution, @device)
    add_breadcrumb 'Custom Mappings', institution_device_custom_mappings_path(@institution, @device)
  end

  def index
    @custom_fields = @device.current_manifest.fields.select &:custom?
    @device.custom_mappings ||= {}
  end

  private

  def load_institution
    @institution = Institution.find params[:institution_id]
    authorize_resource(@institution, READ_INSTITUTION)
  end

  def load_device
    @device = @institution.devices.find params[:device_id]
    authorize_resource(@device, READ_DEVICE)
  end

end
