class RolesController < ApplicationController
  before_filter :load_institutions_and_sites, only: [:new, :create, :edit, :update]

  def index
    @roles = Role.all
  end

  def new
    @role = Role.new
    @users = User.all
  end

  def create
    @role = Role.new(role_params)
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
    @role.definition = JSON.pretty_generate(@role.policy.definition)
  end

  def update
    @role = Role.find params[:id]
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

  private

  def role_params
    params.require(:role).permit(:name, :institution_id, :site_id, :definition)
  end

  def load_institutions_and_sites
    # FIXME: review permissions
    @institutions = check_access(Institution, READ_INSTITUTION)
    @sites = check_access(Site, READ_SITE)
  end
end
