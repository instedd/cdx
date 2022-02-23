module Concerns::ControllerHelper
  extend ActiveSupport::Concern

  def date_format
    { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
  end

  def view_helper(save_back_path = false)
    if save_back_path
      session[:back_path] = URI(request.referer || '').path
    end
    back_path = session[:back_path] || samples_path

    { date_produced_placeholder: date_format[:placeholder], back_path: back_path }
  end

  def back_path()
    session.delete(:back_path) || samples_path
  end

end