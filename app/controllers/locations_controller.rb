class LocationsController < ApplicationController
  before_filter { @in_locations = true }

  def index
    @locations = Location.children(params[:parent_id])
  end

  def show
    @location = Location.find(params[:id], ancestors: true)
  end
end
