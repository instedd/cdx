class InstitutionsController < ApplicationController
  before_filter :load_institutions
  skip_before_filter :check_no_institution!, only: [:new, :create, :pending_approval]
  skip_before_action :ensure_context, except: [:no_data_allowed]

  def index
    @can_create = has_access?(Institution, CREATE_INSTITUTION)

    if @institutions.one?
      redirect_to edit_institution_path(@institutions.first)
    elsif @institutions.empty?
      redirect_to new_institution_path
    end
  end

  def edit
    @institution = check_access(Institution.find(params[:id]), READ_INSTITUTION)
    @readonly = !has_access?(@institution, UPDATE_INSTITUTION)

    @can_delete = has_access?(@institution, DELETE_INSTITUTION)

    @can_create = @institutions.one? && has_access?(Institution, CREATE_INSTITUTION)
  end

  def new
    @institution = current_user.institutions.new
    @institution.user_id = current_user.id
    return unless authorize_resource(Institution, CREATE_INSTITUTION)

    @hide_my_account = @hide_nav_bar = @institutions.count == 0
  end

  def create
    @institution = Institution.new(institution_params)
    @institution.user_id = current_user.id
    return unless authorize_resource(Institution, CREATE_INSTITUTION)

    @hide_my_account = @hide_nav_bar = @institutions.count == 0

    respond_to do |format|
      if @institution.save
        new_context = @institution.uuid

        # Set the new context to the newly created institution
        current_user.last_navigation_context = new_context
        current_user.save!

        # This is needed for the next redirect, which will use it
        params[:context] = new_context

        format.html { redirect_to root_path, notice: 'Institution was successfully created.' }
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
        format.html { redirect_to root_path, notice: 'Institution was successfully updated.' }
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

  def pending_approval
    @hide_nav_bar = true
  end

  def no_data_allowed
    # the no_data_allowed page make sense when the logged user has no access
    # to any of the resources listed in the navbar.
    # Otherwise there is a home to display different from no_data_allowed
    # which filter the data shown per current institution.
    home = after_sign_in_path_for(current_user)
    redirect_to home if home != no_data_allowed_institutions_path
  end

  private

  def load_institutions
    @institutions = check_access(Institution, READ_INSTITUTION) || []
  end

  def institution_params
    params.require(:institution).permit(:name, :kind)
  end
end
