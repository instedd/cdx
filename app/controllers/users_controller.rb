class UsersController < ApplicationController
  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    if can_edit? && @user.update(admin_update_params)
      @_message = "User updated"
    end

    redirect_to edit_user_path(@user), notice: @_message
  end
  private

  def admin_update_params
    params.require(:user).permit(:is_active)
  end

  def can_edit?
    current_user.id != params[:id].to_i
  end
end
