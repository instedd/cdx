class Api::ActivationsController < ApiController
  skip_before_action :authenticate_api_user!

  def create
    activation_token = ActivationToken.find_by(value: params.require(:token))
    response = if activation_token.nil?
      { status: :failure, message: 'Invalid activation token' }
    elsif activation_token.used?
      { status: :failure, message: 'Activation token already used' }
    elsif !activation_token.client_id_valid?
      { status: :failure, message: 'Client id expired' }
    else
      settings = activation_token.use!(params.require(:public_key))
      { status: :success, message: 'Device activated', settings: settings }
    end
    logger.info "Response for activation request #{params[:token]}: #{response}"
    render json: response
  end

end
