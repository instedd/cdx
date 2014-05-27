class InstitutionsController < ApplicationController
  layout "institutions", except: [:index, :new]
  layout "application", only: [:index, :new]

  add_breadcrumb 'Institutions', :institutions_path

  expose(:institution, attributes: :institution_params)

  def index
    @institutions = authorize_access(Institution, "cdp:list_institutions")
  end

  def new
    @institution = current_user.institutions.new
    set_institution_tab :new
  end

  def show
    @institutions = authorize_access(institution, "cdp:list_institutions")

    add_breadcrumb institution.name, institution
    add_breadcrumb 'Overview'
    set_institution_tab :overview
  end

  def edit
    return unless authorize_access(institution, "cdp:edit_institution")

    add_breadcrumb institution.name, institution
    add_breadcrumb 'Settings'
    set_institution_tab :settings
  end

  def create
    respond_to do |format|
      if current_user.create(institution)
        format.html { redirect_to institution, notice: 'Institution was successfully created.' }
        format.json { render action: 'show', status: :created, location: institution }
      else
        format.html { render action: 'new' }
        format.json { render json: institution.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    return unless authorize_access(institution, "cdp:edit_institution")

    respond_to do |format|
      if institution.update(institution_params)
        format.html { redirect_to institution, notice: 'Institution was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: institution.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    return unless authorize_access(institution, "cdp:delete_institution")

    institution.destroy
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
