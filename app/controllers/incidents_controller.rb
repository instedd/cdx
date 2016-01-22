class IncidentsController < ApplicationController
  respond_to :html, :json
  expose(:incidents) { current_user.alert_histories.where({for_aggregation_calculation: false}) }

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def index
    respond_with incidents
  end

  def show
    #    render :edit
  end

end
