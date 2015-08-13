class InstitutionsController < ApplicationController
  layout "institutions", except: [:index, :new, :create]
  layout "application", only: [:index, :new, :create]

  add_breadcrumb 'Institutions', :institutions_path

  def index
    @institutions = check_access(Institution, READ_INSTITUTION)
    @institutions ||= []
  end

  def show
    @institution = Institution.find(params[:id])
    return unless authorize_resource(@institution, READ_INSTITUTION)

    add_breadcrumb @institution.name, @institution
    add_breadcrumb 'Overview'
    set_institution_tab :overview
  end

  def edit
    @institution = Institution.find(params[:id])
    @readonly = !has_access?(@institution, UPDATE_INSTITUTION)

    add_breadcrumb @institution.name, @institution
    add_breadcrumb 'Settings'
    set_institution_tab :settings
  end

  def new
    add_breadcrumb 'New'
    @institution = current_user.institutions.new
    @institution.user_id = current_user.id
    return unless authorize_resource(@institution, CREATE_INSTITUTION)

    @readonly = false
    set_institution_tab :new
  end

  def create
    @institution = Institution.new(institution_params)
    @institution.user_id = current_user.id
    return unless authorize_resource(@institution, CREATE_INSTITUTION)

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
    return unless authorize_resource(@institution, UPDATE_INSTITUTION)

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
    return unless authorize_resource(@institution, DELETE_INSTITUTION)

    @institution.destroy

    respond_to do |format|
      format.html { redirect_to institutions_url }
      format.json { head :no_content }
    end
  end

  def request_api_token
    @institution = Institution.find(params[:id])
    return unless authorize_resource(@institution, READ_INSTITUTION)

    add_breadcrumb @institution.name, @institution
    add_breadcrumb 'Settings', :edit_institution_path
    add_breadcrumb 'Token'
    set_institution_tab :settings

    @token = Guisso.generate_bearer_token current_user.email
  end

  private

  def institution_params
    params.require(:institution).permit(:name)
  end
end
