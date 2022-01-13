class UsersController < ApplicationController
  before_filter :load_resource, only: [:edit, :update, :assign_role, :unassign_role]
  after_filter :create_institution_invite, only: [:create_with_institution_invite]

  def index
    site_admin = !has_access?(@navigation_context.entity, READ_INSTITUTION_USERS) && @navigation_context.entity.kind_of?(Institution)
    if site_admin
      ids = check_access(Site.within(@navigation_context.entity), READ_SITE_USERS).pluck(:id)
    end
    redirect_to no_data_allowed_users_path unless has_access?(@navigation_context.entity, (@navigation_context.entity.kind_of?(Institution) ? READ_INSTITUTION_USERS : READ_SITE_USERS)) || !ids.empty?

    @users = User.within(@navigation_context.entity, @navigation_context.exclude_subsites)
    @users = @users.where("roles.site_id IN (?)", ids) if site_admin
    @context_roles = Role.within(@navigation_context.entity, @navigation_context.exclude_subsites)
    @available_roles = @context_roles.select do |role|
      has_access?(role, ASSIGN_USER_ROLE)
    end
    @available_roles_hash = @available_roles.map { |r| { value: r.id, label: r.name } }
    @context_roles_hash = @context_roles.map { |r| { value: r.id, label: r.name } }
    @can_update = has_access?(User, UPDATE_USER)
    apply_filters
    @total = @users.count

    @date_options = date_options_for_filter
    @status = [{value: "", label: "Show all"}, {value: "1", label: "Active"}, {value: "0", label: "Blocked"}]

    respond_to do |format|
      format.html do
        @users = perform_pagination(@users)
      end
      format.csv do
        filename = "Users-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
        headers["Content-Type"] = "text/csv"
        headers["Content-disposition"] = "attachment; filename=#{filename}"
        self.response_body = build_csv
      end
    end
  end

  def edit
    @user_roles = @user.roles.select { |role| has_access?(role, ASSIGN_USER_ROLE) }
    @user_roles = @user_roles.map { |r| { value: r.id, label: r.name } }
    @can_update = has_access?(User, UPDATE_USER)
  end

  def update
    return unless authorize_resource(@user, UPDATE_USER)
    return head :forbidden unless can_edit?

    message = 'User updated' if @user.update(user_params)
    redirect_to users_path, notice: message || 'There was a problem updating this user'
  end

  def create
    @role = Role.find(params[:role])
    message = params[:message]
    (params[:users] || []).each do |email|
      email = email.strip
      user = User.find_or_initialize_by(email: email)
      send_invitation(message, user) unless user.persisted?
      user.roles << @role unless user.roles.include?(@role)
      ComputedPolicy.update_user(user)
    end
    render nothing: true
  end

  def create_with_institution_invite
    user_invite_data = params[:user_invite_data]
    institution_data = params[:institution_data]
    @message = params[:message]
    @user_email = user_invite_data["email"]
    user = initialize_user(user_invite_data)
    send_institution_invite(institution_data, user)
    user.save!

    render nothing: true
  end

  def assign_role
    if params[:add]
      @user.roles << Role.find(params[:add].to_i)
    else
      role = Role.find(params[:remove].to_i)
      @user.roles.delete(role)
    end
    # Since user is not being updated here, we need to force the new role's policy update
    ComputedPolicy.update_user(@user)
    render nothing: true
  end

  def autocomplete
    users = User.within(@navigation_context.institution)
                .uniq
                .where("first_name LIKE ? OR last_name LIKE ? OR (email LIKE ? AND first_name IS NULL AND last_name IS NULL)", "%#{params["q"]}%", "%#{params["q"]}%", "%#{params["q"]}%")
                .map{|r| {value: r.email, label: r.full_name}}
    render json: users
  end

  def update_setting
    current_user.update_attributes({sidebar_open: params[:sidebar_open]})
    render nothing: true
  end

  def no_data_allowed
    # the no_data_allowed page make sense when the logged user has no access
    # to the resource selected in the navbar.
    redirect_to users_path if has_access?(
      @navigation_context.entity,
      (@navigation_context.entity.is_a?(Institution) ? READ_INSTITUTION_USERS : READ_SITE_USERS))
  end

  private

  def send_institution_invite(institution_data, user)
    mark_as_invited(user)
    InvitationMailer.invite_institution_message(user, institution_data["name"], @message).deliver_now
  end

  def initialize_user(user_invite_data)
    user = User.find_or_initialize_by(email: @user_email.strip)
    unless user.persisted?
      user.first_name = user_invite_data[:firstName]
      user.last_name = user_invite_data[:lastName]
    end
    user
  end

  def send_invitation(message, user)
    mark_as_invited(user)
    InvitationMailer.invite_message(user, @role, message).deliver_now
  end

  def mark_as_invited(user)
    user.invite! do |u|
      u.skip_invitation = true
    end
    user.invitation_sent_at = Time.now.utc # mark invitation as delivered
    user.invited_by_id = current_user.id
  end

  def create_institution_invite
    invited_user = User.find_by(email: @user_email)
    pending_invite = PendingInstitutionInvite.new
    pending_invite.invited_user = invited_user unless invited_user.nil?
    pending_invite.invited_by_user = current_user
    pending_invite.institution_name = params["institution_data"]["name"]
    pending_invite.institution_kind = params["institution_data"]["type"]
    pending_invite.save!
  end

  def user_params
    params.require(:user).permit(:is_active)
  end

  def can_edit?
    current_user.id != @user.try(:id)
  end

  def load_resource
    @user ||= User.find(params[:id])
  end

  def build_csv
    CSV.generate do |csv|
      csv << ["Full name", "Roles", "Last activity"]
      @users.each do |u|
        roles = u.roles.empty? ? nil : "#{u.roles.pluck(:name).join(",")}"
        csv << [u.full_name, roles, ApplicationController.helpers.last_activity(u)]
      end
    end
  end

  def apply_filters
    @users = @users.where("first_name LIKE ? OR last_name LIKE ? OR (email LIKE ? AND first_name IS NULL AND last_name IS NULL)", "%#{params["name"]}%", "%#{params["name"]}%", "%#{params["name"]}%") if params["name"].present?
    # There's no need to redo the join to roles_users because it was done by the scope "within"
    @users = @users.where("roles_users.role_id = ?", params["role"].to_i) if params["role"].present?
    @users = @users.where("last_sign_in_at > ? OR (last_sign_in_at IS NULL AND invitation_accepted_at IS NULL AND invitation_created_at > ?)", params["last_activity"], params["last_activity"]) if params["last_activity"].present?
    @users = @users.where("is_active = ?", params["is_active"].to_i) if params["is_active"].present?
  end
end
