class LaboratoriesController < ApplicationController
  set_institution_tab :laboratories

  def index
    @laboratories = check_access(Laboratory, READ_LABORATORY)
    @laboratories ||= []
    @institutions = check_access(Institution, READ_INSTITUTION)
    @can_create = has_access?(@institutions, CREATE_INSTITUTION_LABORATORY)

    @labs_to_edit = check_access(Laboratory, UPDATE_LABORATORY)
    @labs_to_edit ||= []
    @labs_to_edit.map!(&:id)
  end

  def new
    @institutions = check_access(Institution, READ_INSTITUTION)
    return unless @institutions = authorize_resource(@institutions, CREATE_INSTITUTION_LABORATORY)
    @laboratory = Laboratory.new
    if @institutions.size == 1
      @laboratory.institution = @institutions.first
    end
  end

  # POST /laboratories
  # POST /laboratories.json
  def create
    @institutions = check_access(Institution, CREATE_INSTITUTION_LABORATORY)
    @institution = Institution.find params[:laboratory][:institution_id]
    return unless authorize_resource(@institution, CREATE_INSTITUTION_LABORATORY)

    @laboratory = @institution.laboratories.new(laboratory_params)

    respond_to do |format|
      if @laboratory.save
        format.html { redirect_to laboratories_path, notice: 'Laboratory was successfully created.' }
        format.json { render action: 'show', status: :created, location: @laboratory }
      else
        format.html { render action: 'new' }
        format.json { render json: @laboratory.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @laboratory = Laboratory.find(params[:id])
    return unless authorize_resource(@laboratory, UPDATE_LABORATORY)

    @can_delete = has_access?(@laboratory, DELETE_LABORATORY)
  end

  # PATCH/PUT /laboratories/1
  # PATCH/PUT /laboratories/1.json
  def update
    @laboratory = Laboratory.find params[:id]
    return unless authorize_resource(@laboratory, UPDATE_LABORATORY)

    respond_to do |format|
      if @laboratory.update(laboratory_params)
        format.html { redirect_to laboratories_path, notice: 'Laboratory was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @laboratory.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /laboratories/1
  # DELETE /laboratories/1.json
  def destroy
    @laboratory = Laboratory.find params[:id]
    return unless authorize_resource(@laboratory, DELETE_LABORATORY)

    @laboratory.destroy

    respond_to do |format|
      format.html { redirect_to laboratories_path, notice: 'Laboratory was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  def laboratory_params
    params.require(:laboratory).permit(:name, :address, :city, :state, :zip_code, :country, :region, :lat, :lng, :location_geoid)
  end
end
