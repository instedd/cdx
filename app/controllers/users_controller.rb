class UsersController < ApplicationController
  before_filter :load_resource

  def edit
    return unless authorize_resource(@user, READ_USER)
  end

  def update
    return unless authorize_resource(@user, UPDATE_USER)
    if can_edit? && @user.update(user_params)
      @_message = 'User updated'
    end

    redirect_to edit_user_path(@user), notice: @_message
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
    @_message = 'Unable to load user' unless @user
  end
end
