class RolesController < ApplicationController
  before_filter :load_institutions_and_sites, only: [:new, :create, :edit, :update]

  def index
    @roles = check_access(Role, READ_ROLE).within(@navigation_context.entity, @navigation_context.exclude_subsites).includes(:institution, :site)
    @user_counts = check_access(Role, READ_ROLE).within(@navigation_context.entity, @navigation_context.exclude_subsites).joins("LEFT JOIN roles_users ON roles.id = roles_users.role_id").group("roles.id").count(:user_id)
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
        return render_with_definitions 'new'
      end

      policy = Policy.new name: @role.name, definition: definition, allows_implicit: true
      unless policy.valid?
        policy.errors[:definition].each do |error|
          @role.errors.add :policy, error
        end
        return render_with_definitions 'new'
      end
      @role.policy = policy
    end

    if @role.save
      redirect_to roles_path, notice: 'Role was successfully created.'
    else
      render_with_definitions 'new'
    end
  end

  def edit
    @role = Role.find params[:id]
    return unless authorize_resource(@role, UPDATE_ROLE)

    @role.definition = JSON.pretty_generate(@role.policy.definition)
    @policy_definition_resources = definition_resources_map
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
        render_with_definitions 'edit'
      end
    else
      @role.policy = nil
      @role.definition = role_params[:definition]
      @role.save
      render_with_definitions 'edit'
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

  def search_device
    # FIXME: ensure this correctly filters devices
    devices = check_access(Device, READ_DEVICE).joins(:device_model).includes(:site, :institution, device_model: :institution)
    devices = devices.within(NavigationContext.new(current_user, params[:context]).entity)
    devices = devices.where('devices.name LIKE ? OR devices.uuid LIKE ? OR devices.serial_number LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    render json: as_json_devices_search(devices).attributes!
  end

  private

  def render_with_definitions action
    @policy_definition_resources = definition_resources_map
    render action: action
  end

  def definition_resources_map
    resources = {}
    if @role.policy.try :definition
      @role.policy.definition['statement'].each { |statement|
        (Array.wrap(statement['resource']) + Array.wrap(statement['except'])).each { |resourceKey|
          if matches = resourceKey.match(/device\/(\d+)/) || resourceKey.match(/.*\?device=(\d+)/)
            device_id = matches[1]
            device = Device.find(device_id)
            resources[resourceKey] = as_json_device(device).attributes!
          end
        }
      }
    end
    resources
  end

  def as_json_devices_search(devices)
    Jbuilder.new do |json|
      json.array! devices do |device|
        as_json_device(json, device)
      end
    end
  end

  def as_json_device(json = Jbuilder.new, device)
    json.(device, :uuid, :name, :serial_number, :id)
    json.type :device
    json
  end

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
