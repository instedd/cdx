class UsersController < ApplicationController
  skip_before_filter :ensure_context
  LOCALES = [
              ["English", "en"],
            ]

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

  def settings
    load_locales
  end

  def update_settings
    params = user_params
    if current_user.update(params)
      redirect_to settings_path, notice: "Settings updated"
    else
      load_locales
      render :settings
    end
  end

  private

  def admin_update_params
    params.require(:user).permit(:is_active)
  end

  def can_edit?
    current_user.id != params[:id].to_i
  end

  def user_params
    params.require(:user).permit(:locale, :time_zone, :timestamps_in_device_time_zone)
  end

  def load_locales
    @locales = LOCALES
  end
end
