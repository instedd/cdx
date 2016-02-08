class DashboardsController < ApplicationController
  def index; end

  def nndd
    return unless authorize_resource(TestResult, MEDICAL_DASHBOARD)
  end

end
