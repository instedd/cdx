class Api::ActivationsController < ApiController
  skip_before_action :doorkeeper_authorize!

  def create
    activation_token = ActivationToken.find_by(value: params[:token].delete("-"))
    response = if activation_token.nil?
      { status: :failure, message: 'Invalid activation token' }
    elsif activation_token.used?
      { status: :failure, message: 'Activation token already used' }
    else
      begin
        settings = activation_token.use!(params.require(:public_key))
        { status: :success, message: 'Device activated', settings: settings }
      rescue CDXSync::InvalidPublicKeyError => e
        { status: :failure, message: 'Invalid public key' }
      end
    end
    logger.info "Response for activation request #{params[:token]}: #{response}"
    render json: response
  end
end
