class Api::ActivationsController < ApiController
  respond_to :json

  def create
    activation_token = ActivationToken.find_by(value: params[:token])
    if activation_token && !@activation_token.used?
      activation = activation_token.use!
      respond_with { status: :success, settings: activation.settings }
    else
      respond_with { status: :failure }
    end
  end
end
