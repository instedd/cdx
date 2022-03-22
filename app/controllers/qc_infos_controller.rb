class QcInfosController < ApplicationController
  include Concerns::ViewHelper

  def edit
    @qc_info = QcInfo.find(params[:id])
    @view_helper = view_helper({save_back_path: true})

    authorize_qc_info
    @can_delete = false
    @can_update = false
  end

  private

  def authorize_qc_info
    has_access = @qc_info.samples.any? { |sample| has_access?(sample, READ_SAMPLE) }
    forbid_access(@qc_info.samples.first, READ_SAMPLE) unless has_access
    has_access
  end

end