class LocationsController < ApplicationController
  add_breadcrumb 'Locations', :locations_path

  before_filter { @in_locations = true }
  before_filter :show_ancestors_in_breadcrumb

  def index
    @locations = Location.where(parent_id: params[:parent_id])
  end

  def new
    add_breadcrumb 'New Location'
    if params[:parent_id]
      admin_level = Location.find(params[:parent_id]).admin_level + 1
    end
    @location = Location.new(parent_id: params[:parent_id], admin_level: admin_level)
  end

  def show
    @location = Location.find_by_id params[:id]
  end

  # POST /locations
  # POST /locations.json
  def create
    @location = Location.new(location_params)

    respond_to do |format|
      if @location.save
        format.html { redirect_to locations_path(parent_id: @location.parent_id), notice: 'Location was successfully created.' }
        format.json { render action: 'show', status: :created, location: @location }
      else
        format.html { render action: 'new' }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @location = Location.find(params[:id])
  end

  # PATCH/PUT /locations/1
  # PATCH/PUT /locations/1.json
  def update
    @location = Location.find(params[:id])

    respond_to do |format|
      if @location.update(location_params)
        format.html { redirect_to locations_path(parent_id: @location.parent_id), notice: 'Location was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /locations/1
  # DELETE /locations/1.json
  def destroy
    @location = Location.find(params[:id])

    if @location.destroy
      respond_to do |format|
        format.html { redirect_to locations_path(parent_id: @location.parent_id) }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html do
          render action: 'edit'
        end
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def location_params
    params.require(:location).permit(:name, :parent_id, :admin_level, :geo_id)
  end

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
