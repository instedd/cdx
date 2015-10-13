class ProspectsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :check_no_institution!
  skip_before_action :load_current_user_policies

  def approve
    Prospect.where(uuid: params[:id]).tap do |prospects|
      invite(prospects.first) if prospects.any?
      redirect_to prospects_path
    end
  end

  def index
    @prospects = Prospect.all
  end

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

  def invite(prospect)
    User.invite!(email: prospect.email).tap do |user|
      prospect.update_attribute(:uuid, nil)
    end
  end

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
