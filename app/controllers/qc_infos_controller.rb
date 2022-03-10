class QcInfosController < ApplicationController
  include Concerns::ViewHelper

  def edit
    @qc_info = QcInfo.find(params[:id])
    @view_helper = view_helper({save_back_path: true})

    return unless authorize_resource(@qc_info.samples.first, READ_SAMPLE)
    @can_delete = false
    @can_update = false
  end

end