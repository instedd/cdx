class InstitutionsController < ApplicationController
  layout "institutions"
  before_filter :load_institutions, except: :index
  skip_before_filter :check_no_institution!, only: [:new, :create]

  def index
    @can_create = true
    @institutions = check_access(Institution, READ_INSTITUTION)
    @institutions ||= []
    if @institutions.one?
      redirect_to edit_institution_path(@institutions.first)
    end
  end

  def edit
    @institution = Institution.find(params[:id])
    @readonly = !has_access?(@institution, UPDATE_INSTITUTION)

    unless has_access?(@institution, UPDATE_INSTITUTION)
      redirect_to institution_path(@institutions.first)
    end

    @institutions = check_access(Institution, READ_INSTITUTION)
    @can_delete = has_access?(@institution, "cdpx:deleteInstitution")

    if @institutions.one?
      @can_create = true
    end
  end

  def new
    @institution = current_user.institutions.new
    @institution.user_id = current_user.id
    return unless authorize_resource(Institution, CREATE_INSTITUTION)

    @first_institution_creation = @institutions.count == 0
    @hide_user_settings = @hide_nav_bar = @first_institution_creation
  end

  def create
    @institution = Institution.new(institution_params)
    @institution.user_id = current_user.id
    return unless authorize_resource(Institution, CREATE_INSTITUTION)

    @first_institution_creation = @institutions.count == 0
    @hide_user_settings = @hide_nav_bar = @first_institution_creation

    respond_to do |format|
      if @institution.save
        format.html { redirect_to institutions_path, notice: 'Institution was successfully created.' }
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
        format.html { redirect_to institutions_path, notice: 'Institution was successfully updated.' }
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

    @token = Guisso.generate_bearer_token current_user.email
  end

  private

  def load_institutions
    @institutions = check_access(Institution, READ_INSTITUTION)
  end

  def institution_params
    params.require(:institution).permit(:name)
  end
end
