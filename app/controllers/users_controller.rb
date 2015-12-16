class UsersController < ApplicationController
  LOCALES = [
              ["English", "en"],
            ]

  def settings
    load_locales
  end

  def update_settings
    params = user_params
    if params[:password].blank? && params[:password_confirmation].blank?
      params.delete(:password)
      params.delete(:password_confirmation)
    end
    if current_user.update(params)
      sign_in current_user, :bypass => true
      redirect_to settings_path, notice: "Settings updated"
    else
      load_locales
      render :settings
    end
  end

  private

  def user_params
    params.require(:user).permit(:locale, :time_zone, :timestamps_in_device_time_zone, :password, :password_confirmation)
  end

  def load_locales
    @locales = LOCALES
  end
end
