class InstitutionsController < ApplicationController
  before_filter :load_institutions
  skip_before_filter :check_no_institution!, only: [:new, :create, :pending_approval, :new_from_invite_data]
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
    inst_params = institution_params
    pending_invite_id = get_pending_invite_id_from_params(inst_params)

    if pending_invite_id
      @pending_invite = PendingInstitutionInvite.find_by(id: pending_invite_id )

      unless @pending_invite and @pending_invite.status == 'pending'
        no_data_allowed
        return
      end
    end

    @institution = Institution.new(inst_params)
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

        #set pending institution invite as accepted if it is not nil
        accept_pending_invite unless @pending_invite.nil?

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

  def new_from_invite_data
    pending_institution_invite_id = get_pending_invite_id_from_params(params)
    pending_invite = PendingInstitutionInvite.find_by(invited_user_email: current_user.email,  id: pending_institution_invite_id, status: 'pending')
    unless pending_invite.nil?
      @institution = current_user.institutions.new
      @institution.kind = pending_invite.institution_kind
      @institution.name = pending_invite.institution_name
      @institution.pending_institution_invite = pending_invite
      render action: 'new'
    else
      session[:user_return_to] = nil
      no_data_allowed
    end
  end

  def accept_pending_invite
    unless @pending_invite.nil? and current_user.email != @pending_invite.invited_user_email
      @pending_invite.status = 'accepted'
      @pending_invite.save!
    end
  end

  private

  def load_institutions
    @institutions = check_access(Institution, READ_INSTITUTION) || []
  end

  def institution_params
    params.require(:institution).permit(:name, :kind, :pending_institution_invite_id)
  end

  def get_pending_invite_id_from_params(inst_params)
    (inst_params.has_key?(:pending_institution_invite_id)) ? inst_params["pending_institution_invite_id"] : nil
  end
end
