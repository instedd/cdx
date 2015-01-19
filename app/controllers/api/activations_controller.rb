class Api::ActivationsController < ApiController
  skip_before_action :authenticate_api_user!

  def create
    activation_token = ActivationToken.find_by(value: params[:token])
    if activation_token && !@activation_token.used?
      if activation_token.device_secret_key_valid?
        activation = activation_token.use!(params[:public_key])
        render json: { status: :success, settings: activation.settings }
      else
        render json: { status: :failure, settings: activation.settings }
      end
    else
      render json: { status: :failure }
    end
  end
end
