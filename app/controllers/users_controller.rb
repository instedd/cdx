class UsersController < ApplicationController
  before_filter :load_resource, only: [:edit, :update]

  def index
    return unless authorize_resource(@navigation_context.entity, (@navigation_context.entity.kind_of?(Institution) ? READ_INSTITUTION_USERS : READ_SITE_USERS))
    @users = User.within(@navigation_context.entity)
    @users_to_edit = check_access(@users, UPDATE_USER).pluck(:id)
  end

  def edit
    return unless authorize_resource(@user, UPDATE_USER)
  end

  def update
    return unless authorize_resource(@user, UPDATE_USER)
    return head :forbidden unless can_edit?

    message = 'User updated' if @user.update(user_params)
    redirect_to users_path, notice: message || 'There was a problem updating this user'
  end

  def new
    @roles = Role.within(@navigation_context.entity)
  end

  def create
    users = []
    @role = Role.find(params[:role])
    params[:users].split(',').each do |email|
      email = email.strip
      user = User.find_or_initialize_by(email: email)
      user.invite! unless user.persisted?
      user.roles << @role
    end
    redirect_to users_path
  end

  private

  def user_params
    params.require(:user).permit(:is_active)
  end

  def can_edit?
    current_user.id != @user.try(:id)
  end

  def load_resource
    @user ||= User.find(params[:id])
  end
end
