class IncidentsController < ApplicationController
  respond_to :html, :json

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def index
    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    offset = (@page - 1) * @page_size

    @incidents =  current_user.alert_histories.where({for_aggregation_calculation: false}).joins(:alert)
    @total = @incidents.count
    @incidents = @incidents.limit(@page_size).offset(offset)

    respond_with @incidents
  end
end
