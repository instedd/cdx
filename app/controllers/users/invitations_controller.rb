class Users::InvitationsController < Devise::InvitationsController
  def new
    @user = User.new
    @user.policies.build
    render :new
  end

  def create
    User.invite!(email: user_params["email"]).tap do |user|
      # TODO add policy to user object here
    end
    render :new
  end

  private

  def user_params
    params.require(:user).permit(
      :email,
      policies_attributes: [:definition]
    )
  end
end
