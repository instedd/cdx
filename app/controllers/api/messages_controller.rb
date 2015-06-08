class Api::MessagesController < ApiController
  wrap_parameters false
  skip_before_action :authenticate_api_user!, only: :create
  skip_before_action :load_current_user_policies, only: :create

  def create
    if current_user && !params[:authentication_token]
      devices_scope = current_user.devices
    else
      devices_scope = Device.all
    end

    device = devices_scope.includes(:manifests, :institution, :laboratories).find_by_uuid(params[:device_id])

    if authenticate_create(device)
      data = request.body.read rescue nil
      device_message = DeviceMessage.new(device: device, plain_text_data: data)

      if device_message.save
        if device_message.index_failed?
          render :status => :unprocessable_entity, :json => { :errors => device_message.index_failure_reason }
        else
          device_message.process
          render :status => :ok, :json => { :messages => device_message.parsed_messages }
        end
      else
        render :status => :unprocessable_entity, :json => { :errors => device_message.errors.full_messages.join(', ') }
      end
    else
      head :unauthorized
    end
  end

  private

  def authenticate_create(device)
    token = params[:authentication_token]
    return true if current_user && !token
    token ||= basic_password
    return false unless token
    device.validate_authentication(token)
  end

  def basic_password
    ActionController::HttpAuthentication::Basic.authenticate(request) do |user, password|
      password
    end
  end
end
