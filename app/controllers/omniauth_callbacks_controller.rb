class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_before_filter :check_guisso_cookie

  def instedd
    generic do |auth|
      {
        email: auth.info['email'],
        # name: auth.info['name'],
      }
    end
  end

  def generic
    auth = env['omniauth.auth']

    if identity = Identity.find_by_provider_and_token(auth['provider'], auth['uid'])
      user = identity.user
    else
      attributes = yield auth

      attributes[:confirmed_at] = Time.now

      user = User.find_by_email(attributes[:email])
      unless user
        password = Devise.friendly_token
        user = User.create!(attributes.merge(password: password, password_confirmation: password))
      end
      user.identities.create! provider: auth['provider'], token: auth['uid']
    end

    sign_in user
    puts "Current user: #{current_user}"

    next_url = env['omniauth.origin'] || root_path
    next_url = root_path if next_url == new_user_session_url
    redirect_to next_url
  end
end
