class QcInfosController < ApplicationController

  def edit
    @qc_info = QcInfo.find(params[:id])
    @view_helper = view_helper({save_back_path: true})

    return unless authorize_resource(@qc_info.samples.first, READ_SAMPLE)
    @can_delete = false
    @can_update = false
  end

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

end