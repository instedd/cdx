class ApiController < ApplicationController
  include ApplicationHelper
  include Policy::Actions

  skip_before_filter :verify_authenticity_token

  def build_csv prefix, builder
    @csv_options = { :col_sep => ',' }
    @csv_builder = builder
    @filename = "#{prefix}-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
  end
end
