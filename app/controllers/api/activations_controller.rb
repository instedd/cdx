class Api::ActivationsController < ApiController
  skip_before_action :doorkeeper_authorize!

  def create
    device = Device.find_by(activation_token: params[:token].delete("-"))
    response = if device.nil?
        { status: :failure, message: 'Invalid activation token' }
      elsif params[:public_key]
        begin
          settings = device.use_activation_token_for_ssh_key!(params[:public_key])
          { status: :success, message: 'Device activated', settings: settings }
        rescue CDXSync::InvalidPublicKeyError => e
          { status: :failure, message: 'Invalid public key' }
        end
      elsif params[:generate_key]
        secret_key = device.use_activation_token_for_secret_key!
        { status: :success, message: 'Device activated', settings: { device_key: secret_key, device_uuid: device.uuid } }
      else
        { status: :failure, message: 'Missing public_key or generate_key parameter' }
      end

    logger.info "Response for activation request #{params[:token]}: #{response}"
    render json: response
  end
end
