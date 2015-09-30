class DeviceLogsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:create]
  skip_before_filter :authenticate_user!, only: [:create]

  def index
    @device = Device.find params[:device_id]
    authorize_resource(@device, READ_DEVICE)
    @device_logs = @device.device_logs.order(created_at: :desc)
  end

  def show
    @device = Device.find params[:device_id]
    authorize_resource(@device, READ_DEVICE)

    log = @device.device_logs.find params[:id]
    filename = "#{@device.name} logs - #{log.created_at.in_time_zone(@device.time_zone).strftime('%Y%m%d%H%M%S')}.txt"
    filename = filename.gsub(/^.*(\\|\/)/, '').gsub(/[^0-9A-Za-z.\- ]/, '_')
    send_data log.message, filename: filename, type: "text/plain"
  end

  def create
    device = Device.find_by_uuid params[:device_id]
    unless device
      return head(:not_found)
    end

    unless device.validate_authentication(params[:key])
      return head(:forbidden)
    end

    device.device_logs.create! message: request.raw_post

    head :ok
  end
end
