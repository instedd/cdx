class ProspectsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :check_no_institution!
  skip_before_action :load_current_user_policies

  def new
    @prospect = UserRequest.new
  end

  def create
    @prospect = UserRequest.new(prospect_params)
    if @prospect.valid?
      @prospect.save!
      redirect_to root_path, notice: I18n.t('access_request.submitted')
    else
      render :new
    end
  end

  private

  def prospect_params
    return {} unless params[:user_request].any?
    params.require(:user_request).permit(
      :first_name,
      :last_name,
      :email,
      :contact_number
    )
  end
end
