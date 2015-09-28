class DeviceLogsController < ApplicationController
  before_filter :load_device, except: [:create]

  skip_before_filter :verify_authenticity_token, only: [:create]
  skip_before_filter :authenticate_user!, only: [:create]

  def index
    @device_logs = @device.device_logs.order(created_at: :desc)
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
    authorize_resource(@device, READ_DEVICE)
  end
end
