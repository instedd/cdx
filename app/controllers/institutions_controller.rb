class InstitutionsController < ApplicationController
  layout "institutions", except: [:index, :new]
  layout "application", only: [:index, :new]

  add_breadcrumb 'Institutions', :institutions_path

  def index
    @institutions = authorize_resource(Institution, "cdpx:readInstitution")
  end

  def show
    @institution = Institution.find(params[:id])
    return unless authorize_resource(@institution, "cdpx:readInstitution")

    add_breadcrumb @institution.name, @institution
    add_breadcrumb 'Overview'
    set_institution_tab :overview
  end

  def edit
    @institution = Institution.find(params[:id])
    @readonly = !has_access?(@institution, "cdpx:editInstitution")

    add_breadcrumb @institution.name, @institution
    add_breadcrumb 'Settings'
    set_institution_tab :settings
  end

  def new
    @institution = current_user.institutions.new
    @institution.user_id = current_user.id
    return unless authorize_resource(@institution, "cdpx:createInstitution")

    @readonly = false
    set_institution_tab :new
  end

  def create
    @institution = Institution.new(institution_params)
    @institution.user_id = current_user.id
    return unless authorize_resource(@institution, "cdpx:createInstitution")

    respond_to do |format|
      if @institution.save
        format.html { redirect_to @institution, notice: 'Institution was successfully created.' }
        format.json { render action: 'show', status: :created, location: @institution }
      else
        format.html { render action: 'new' }
        format.json { render json: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @institution = Institution.find(params[:id])
    return unless authorize_resource(@institution, "cdpx:updateInstitution")

    respond_to do |format|
      if @institution.update(institution_params)
        format.html { redirect_to @institution, notice: 'Institution was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @institution = Institution.find(params[:id])
    return unless authorize_resource(@institution, "cdpx:deleteInstitution")

    @institution.destroy

    respond_to do |format|
      format.html { redirect_to institutions_url }
      format.json { head :no_content }
    end
  end

  private

  def institution_params
    params.require(:institution).permit(:name)
  end
end
