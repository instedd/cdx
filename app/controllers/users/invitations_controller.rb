class Users::InvitationsController < Devise::InvitationsController
  def new
    @user = User.new
    @user.policies.build
    render :new
  end

  def create
    User.invite!(email: user_params["email"]).tap do |user|
      if user.errors.empty?

        # TODO add policy to user object here
        
        if is_flashing_format? && user.invitation_sent_at
          set_flash_message :notice, :send_instructions, email: user.email
        end
        respond_with user, location: after_invite_path_for(current_inviter)
      else
        respond_with_navigational(user) { render :new }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :email,
      policies_attributes: [:definition]
    )
  end
end
