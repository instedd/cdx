class SettingsController < ApplicationController
  before_filter :load_locales
  skip_before_filter :ensure_context

  def edit; end

  def update
    if current_user.update(user_params)
      redirect_to settings_path, notice: I18n.t('user.settings.updated')
    else
      render :settings
    end
  end

  private

  def load_locales
    @locales ||= [%w(English en)]
  end

  def user_params
    params.require(:user).permit(
      :locale,
      :time_zone,
      :timestamps_in_device_time_zone
    )
  end
end
