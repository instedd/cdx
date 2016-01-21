class RolesController < ApplicationController
  before_filter :load_institutions_and_sites, only: [:new, :create, :edit, :update]

  def index
    @roles = check_access(Role, READ_ROLE).within(@navigation_context.entity).includes(:institution, :site)
    @user_counts = check_access(Role, READ_ROLE).within(@navigation_context.entity).joins("LEFT JOIN roles_users ON roles.id = roles_users.role_id").group("roles.id").count(:user_id)
    @can_create = has_access?(Role, UPDATE_ROLE)

    @roles = @roles.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
  end

  def new
    @role = Role.new
  end

  def create
    @institution = @navigation_context.institution
    return unless authorize_resource(@institution, CREATE_INSTITUTION_ROLE)
    @role = @institution.roles.new(role_params)

    if @role.name.present? && (definition = role_params[:definition]).present?
      begin
        definition = JSON.parse(definition)
      rescue => ex
        @role.errors.add :policy, ex.message
        return render action: 'new'
      end

      policy = Policy.new name: @role.name, definition: definition, allows_implicit: true
      unless policy.valid?
        policy.errors[:definition].each do |error|
          @role.errors.add :policy, error
        end
        return render action: 'new'
      end
      @role.policy = policy
    end

    if @role.save
      redirect_to roles_path, notice: 'Role was successfully created.'
    else
      render action: 'new'
    end
  end

  def edit
    @role = Role.find params[:id]
    return unless authorize_resource(@role, UPDATE_ROLE)

    @role.definition = JSON.pretty_generate(@role.policy.definition)
    @can_delete = has_access?(@role, DELETE_ROLE)
  end

  def update
    @role = Role.find params[:id]
    return unless authorize_resource(@role, UPDATE_ROLE)

    if (definition = role_params[:definition]).present?
      begin
        definition = JSON.parse(definition)
      rescue => ex
        @role.definition = role_params[:definition]
        @role.errors.add :policy, ex.message
        return render action: 'edit'
      end

      policy = @role.policy
      policy.definition = definition
      policy.allows_implicit = true
      if policy.save
        redirect_to roles_path, notice: 'Role was successfully updated.'
      else
        policy.errors[:definition].each do |error|
          @role.errors.add :policy, error
        end
        @role.definition = role_params[:definition]
        render action: 'edit'
      end
    else
      @role.policy = nil
      @role.definition = role_params[:definition]
      @role.save
      render action: 'edit'
    end
  end

  def destroy
    @role = Role.find params[:id]
    return unless authorize_resource(@role, DELETE_ROLE)

    @role.destroy
    redirect_to roles_path, notice: 'Role was successfully deleted.'
  end

  def autocomplete
    roles = check_access(Role, READ_ROLE).where('name LIKE ?', "%#{params[:q]}%".gsub("'", "")).map{|r| {value: r.id, label: r.name}}
    render json: roles
  end


  private

  def role_params
    params.require(:role).permit(:name, :site_id, :definition)
  end

  def load_institutions_and_sites
    # FIXME: review permissions
    @institution = @navigation_context.institution
    @accessible_institutions = check_access(Institution, READ_INSTITUTION).count
    @sites = check_access(Site, CREATE_SITE_ROLE).within(@institution)
  end
end
