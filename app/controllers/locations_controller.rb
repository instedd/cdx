class LocationsController < ApplicationController
  add_breadcrumb 'Locations', :locations_path

  before_filter { @in_locations = true }

  def index
    @locations = Location.all
  end

  def new
    @location = Location.new
  end

  # POST /locations
  # POST /locations.json
  def create
    @location = Location.new(location_params)

    respond_to do |format|
      if @location.save
        format.html { redirect_to locations_path, notice: 'Location was successfully created.' }
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
        format.html { redirect_to locations_path, notice: 'Location was successfully updated.' }
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

    @location.destroy
    respond_to do |format|
      format.html { redirect_to locations_path }
      format.json { head :no_content }
    end
  end

  private

  def location_params
    params.require(:location).permit(:name, :parent_id)
  end
end
