class DashboardsController < ApplicationController
  before_filter :set_width

  def nndd
    return unless authorize_resource(TestResult, MEDICAL_DASHBOARD)
  end

  def set_width
    @main_column_width = 10
  end
end
