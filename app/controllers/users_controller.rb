class UsersController < ApplicationController
  before_filter :load_resource

  def edit
    return unless authorize_resource(@user, READ_USER)
  end

  def update
    return unless authorize_resource(@user, UPDATE_USER)
    return head :forbidden unless can_edit?

    message = 'User updated' if @user.update(user_params)

    redirect_to edit_user_path(@user),
                notice: message || 'There was a problem updating this user'
  end
  private

  def user_params
    params.require(:user).permit(:is_active)
  end

  def can_edit?
    current_user.id != @user.try(:id)
  end

  def load_resource
    @user ||= User.find(params[:id])
  end
end
