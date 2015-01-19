class Api::ActivationsController < ApiController
  respond_to :json

  def create
    activation_token = ActivationToken.find_by(value: params[:token])
    if activation_token && !@activation_token.used?
      if activation_token.device_secret_key_valid?
        activation = activation_token.use!(params[:public_key])
        respond_with { status: :success, settings: activation.settings }
      else
        respond_with { status: :failure, settings: activation.settings }
      end
    else
      respond_with { status: :failure }
    end
  end
end
