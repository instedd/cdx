class UsersController < ApplicationController
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
    params.require(:user).permit(:locale)
  end

  def load_locales
    @locales = Hash[I18n.available_locales.map do |locale|
      [I18n.t!(:language_name, locale: locale), locale] rescue nil
    end.compact!]
  end
end
