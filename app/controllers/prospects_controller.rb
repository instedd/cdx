class ProspectsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :check_no_institution!
  skip_before_action :load_current_user_policies

  def approve
    Prospect.where(uuid: params[:id]).tap do |prospects|
      if prospects.any?
        invite(prospects.first)
        redirect_to prospects_url,
                    notice: "Successfully approved #{prospects.first.email}"
      else
        redirect_to prospects_url,
                    warn: 'Could not find request to approve'
      end
    end
  end

  def create
    @prospect = Prospect.new(prospect_params)
    if @prospect.valid?
      @prospect.save!
      redirect_to root_path, notice: I18n.t('access_request.submitted')
    else
      render :new
    end
  end

  def index
    @prospects = Prospect.pending
  end

  def new
    @prospect = Prospect.new
  end

  def reject
    Prospect.where(uuid: params[:id]).tap do |prospects|
      deny(prospects.first) if prospects.any?
      redirect_to prospects_path
    end
  end

  private

  def deny(prospect)
    prospect.update_attribute(:uuid, nil)
  end

  def invite(prospect)
    User.invite!(email: prospect.email).tap do |user|
      prospect.update_attribute(:uuid, nil)
    end
  end

  def prospect_params
    return {} unless params[:prospect].any?
    params.require(:prospect).permit(
      :first_name,
      :last_name,
      :email,
      :contact_number
    )
  end
end
