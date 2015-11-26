class AlertsController < ApplicationController
  respond_to :html, :json
  expose(:alerts) { current_user.alerts }
  expose(:alert, attributes: :alert_params)

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def index
    respond_with alerts
  end

  def edit
    @editing = true
    respond_with alert, location: alert_path
  end

  def show
    respond_with alert, location: alert_path
  end

  def create
    flash[:notice] = "Alert was successfully created" if alert.save
    respond_with alert, location: alerts_path
  end

  def update
    flash[:notice] = "Alert was successfully updated" if alert.save
    respond_with alert, location: alerts_path
  end

  def destroy
    if alert.destroy
      flash[:notice] = "alert was successfully deleted"
      respond_with alert
    else
      render :edit
    end
  end

  private

  def alert_params
    params.require(:alert).permit(:name, :description)
  end
end
