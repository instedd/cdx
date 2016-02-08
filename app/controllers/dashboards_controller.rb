class DashboardsController < ApplicationController
  def index
    Reports::Base.process(current_user, @navigation_context)
  end

  def nndd
    return unless authorize_resource(TestResult, MEDICAL_DASHBOARD)
  end

end
