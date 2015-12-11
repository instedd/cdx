class IncidentsController < ApplicationController
  respond_to :html, :json
  expose(:incidents) { current_user.alert_histories }

#  expose(:filter, attributes: :filter_params)

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def index
    respond_with incidents
  end

  def show
#    render :edit
  end

  private

  def filter_params
   # params.require(:filter).permit(:name).tap do |whitelisted|
  #    whitelisted[:query] = params[:filter][:query] || {}
  #  end
  end
  
end
