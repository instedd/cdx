class Api::ActivationsController < ApiController
  skip_before_action :doorkeeper_authorize!

  def create
    device = Device.find_by(activation_token: params[:token].delete("-"))
    response = if device.nil?
      { status: :failure, message: 'Invalid activation token' }
    else
      begin
        settings = device.use_activation_token!(params.require(:public_key))
        { status: :success, message: 'Device activated', settings: settings }
      rescue CDXSync::InvalidPublicKeyError => e
        { status: :failure, message: 'Invalid public key' }
      end
    end
    logger.info "Response for activation request #{params[:token]}: #{response}"
    render json: response
  end
end
