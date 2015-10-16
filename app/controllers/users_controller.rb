class UsersController < ApplicationController
  LOCALES = [
              ["English", "en"],
            ]

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

  def user_params
    params.require(:user).permit(:locale, :time_zone, :timestamps_in_device_time_zone)
  end

  def load_locales
    @locales = LOCALES
  end
end
