class LocationsController < ApplicationController
  expose(:locations)
  expose(:current_location, model: :location, attributes: :location_params)

  add_breadcrumb 'Locations', :locations_path

  before_filter { @in_locations = true }

  # POST /locations
  # POST /locations.json
  def create
    respond_to do |format|
      if current_location.save
        format.html { redirect_to locations_path, notice: 'Location was successfully created.' }
        format.json { render action: 'show', status: :created, location: current_location }
      else
        format.html { render action: 'new' }
        format.json { render json: current_location.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /locations/1
  # PATCH/PUT /locations/1.json
  def update
    respond_to do |format|
      if current_location.update(location_params)
        format.html { puts "ACA!"; redirect_to locations_path, notice: 'Location was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: current_location.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /locations/1
  # DELETE /locations/1.json
  def destroy
    current_location.destroy
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
