class DashboardsController < ApplicationController

  def nndd
    return unless authorize_resource(TestResult, MEDICAL_DASHBOARD)
  end

end
