class LocationsController < ApplicationController
  add_breadcrumb 'Locations', :locations_path

  before_filter { @in_locations = true }
  before_filter :show_ancestors_in_breadcrumb

  def index
    @locations = Location.children(params[:parent_id])
  end

  def show
    @location = Location.find(params[:id], ancestors: true)
  end

  private

  def show_ancestors_in_breadcrumb
    parent_id = params[:parent_id] || params[:id]
    return if !parent_id

    Location.find(parent_id, ancestors: true).self_and_ancestors.each do |ancestor|
      add_breadcrumb ancestor.name, locations_path(parent_id: ancestor.id)
    end
  end
end
