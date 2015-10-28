class ApiTokensController < ApplicationController
  def index
    @api_tokens = current_user.default_oauth2_application.access_tokens
  end

  def new
    current_user.create_api_token
    redirect_to api_tokens_path
  end

  def destroy
    token = current_user.default_oauth2_application.access_tokens.find params[:id]
    token.destroy

    redirect_to api_tokens_path, notice: "API Token deleted"
  end
end