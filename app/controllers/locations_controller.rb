class LocationsController < ApplicationController
  add_breadcrumb 'Locations', :locations_path

  before_filter { @in_locations = true }
  before_filter :show_ancestors_in_breadcrumb

  def index
    # TODO: Reimplement
  end

  private

  def show_ancestors_in_breadcrumb
    ancestors = []
    parent_id = params[:parent_id] || params[:id]

    while parent_id
      ancestors << ancestor = Location.find(parent_id)
      parent_id = ancestor.parent_id
    end
    ancestors.reverse_each do |ancestor|
      add_breadcrumb ancestor.name, locations_path(parent_id: ancestor.id)
    end
  end
end
