class LaboratoriesController < ApplicationController
  layout "institutions"
  set_institution_tab :laboratories

  add_breadcrumb 'Institutions', :institutions_path

  before_filter :load_institution

  before_filter do
    add_breadcrumb @institution.name, institution_path(@institution)
    add_breadcrumb 'Laboratories', institution_laboratories_path(@institution)
  end

  def index
    @laboratories = authorize_resource(@institution.laboratories, READ_LABORATORY)
  end

  def new
    @laboratory = @institution.laboratories.new
    return unless authorize_resource(@laboratory, CREATE_LABORATORY)
  end

  # POST /laboratories
  # POST /laboratories.json
  def create
    @laboratory = @institution.laboratories.new(laboratory_params)
    return unless authorize_resource(@laboratory, CREATE_LABORATORY)

    respond_to do |format|
      if current_user.create(@laboratory)
        format.html { redirect_to institution_laboratories_path(@institution), notice: 'Laboratory was successfully created.' }
        format.json { render action: 'show', status: :created, location: @laboratory }
      else
        format.html { render action: 'new' }
        format.json { render json: @laboratory.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @laboratory = @institution.laboratories.find params[:id]
    return unless authorize_resource(@laboratory, UPDATE_LABORATORY)

    add_breadcrumb @laboratory.name, institution_laboratory_path(@institution, @laboratory)
  end

  # PATCH/PUT /laboratories/1
  # PATCH/PUT /laboratories/1.json
  def update
    @laboratory = @institution.laboratories.find params[:id]
    return unless authorize_resource(@laboratory, UPDATE_LABORATORY)

    respond_to do |format|
      if @laboratory.update(laboratory_params)
        format.html { redirect_to institution_laboratories_path(@institution), notice: 'Laboratory was successfully updated.' }
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
    @laboratory = @institution.laboratories.find params[:id]
    return unless authorize_resource(@laboratory, DELETE_LABORATORY)

    @laboratory.destroy

    respond_to do |format|
      format.html { redirect_to institution_laboratories_url(@institution) }
      format.json { head :no_content }
    end
  end

  private

  def load_institution
    @institution = Institution.find params[:institution_id]
    authorize_resource(@institution, READ_INSTITUTION)
  end

  def laboratory_params
    params.require(:laboratory).permit(:name, :address, :city, :state, :zip_code, :country, :region, :lat, :lng, :location_id)
  end
end
