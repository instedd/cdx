class Api::ActivationsController < ApiController
  skip_before_action :authenticate_api_user!

  def create
    activation_token = ActivationToken.find_by(value: params[:token])
    if activation_token.nil?
      render json: { status: :failure, message: 'Invalid activation token' }
    elsif @activation_token.used?
      render json: { status: :failure, message: 'Activation token already used' }
    elsif !activation_token.client_id_valid?
      render json: { status: :failure, message: 'Client id expired', settings: settings }
    else
      settings = activation_token.use!(params[:public_key])
      render json: { status: :success, message: 'Device activated', settings: settings }
    end
  end

end
