class DeviceEventsController < ApplicationController
  layout "institutions"
  set_institution_tab :devices

  add_breadcrumb 'Institutions', :institutions_path

  before_filter :load_institution
  before_filter :load_device
  before_filter :load_event, only: [:raw, :reprocess]

  before_filter do
    add_breadcrumb @institution.name, institution_path(@institution)
    add_breadcrumb 'Devices', institution_devices_path(@institution)
    add_breadcrumb @device.name, institution_device_path(@institution, @device)
  end

  def index
    add_breadcrumb 'Events', institution_device_device_events_path(@institution, @device)

    @events = @device.device_events
  end

  def raw
    ext, type = case @device.current_manifest.data_type
    when 'json'
      ['json', 'application/json']
    when 'csv', 'headless_csv'
      ['csv', 'text/csv']
    else
      ['txt', 'text/plain']
    end

    send_data @event.plain_text_data, filename: "event_#{@event.id}.#{ext}", type: type
  end

  def reprocess
    @event.reprocess
    redirect_to institution_device_device_events_path(@institution, @device),
                notice: 'The event will be reprocessed'
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

  def load_event
    @event = @device.device_events.find(params[:id])
  end
end
