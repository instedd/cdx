class RegistrationsController < Devise::RegistrationsController

  before_filter :load_locales
  skip_before_filter :ensure_context

  protected

  # Do not require current password for update, since a user registered via Omniauth has an unknown random password assigned
  # TODO: Remove required password validation for users signed up via Omniauth, and do require current password here
  def update_resource(resource, params)
    # Do not update password if nothing is entered
    if params[:password].blank?
      params.delete(:password)
      params.delete(:password_confirmation)
    else
      # Avoid security issue when password can be updated by not sending password confirmation
      params[:password_confirmation] ||= ""
    end
    # Update the resource as usual
    result = resource.update(params)
    clean_up_passwords(resource)
    result
  end

  def after_update_path_for(resource)
    edit_user_registration_path
  end

  private

  def load_locales
    @locales ||= [%w(English en)]
  end

  def sign_up_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation, :locale, :time_zone, :timestamps_in_device_time_zone)
  end
end
