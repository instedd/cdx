class DeviceLogsController < ApplicationController
  before_filter :load_device, only: [:index, :show]

  skip_before_filter :verify_authenticity_token, only: [:create]
  skip_before_filter :authenticate_user!, only: [:create]
  skip_before_filter :ensure_context, only: [:create]

  def index
    @device_logs = @device.device_logs.order(created_at: :desc)
  end

  def show
    log = @device.device_logs.find params[:id]
    filename = "#{@device.name} logs - #{log.created_at.in_time_zone(@device.time_zone).strftime('%Y%m%d%H%M%S')}.txt"
    filename = filename.gsub(/[^0-9A-Za-z.\-]/, '_')
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

  private

  def load_device
    @device = Device.find params[:device_id]
    authorize_resource(@device, SUPPORT_DEVICE)
  end
end
