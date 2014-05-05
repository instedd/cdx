class UsersController < ApplicationController
  add_breadcrumb 'Users', :users_path

  before_filter { @in_users = true }

  expose(:users) { User.where("id != ?", current_user.id) }
  expose(:user)

  expose(:institutions) { current_user.visible_institutions.includes(:laboratories, :devices).all }
  expose(:locations) { Location.roots }

  expose(:roles) { user.roles.all }
  expose(:current_user_roles) { current_user.roles.all }

  def show
    add_breadcrumb user.email, user
  end

  def update
    roles = params[:roles] || []

    if current_user.has_role?(:admin)
      # Need to delete all applies roles
      roles_to_delete = user.roles
    else
      # We need to delete those roles which the current user has access to
      roles_to_delete = current_user.roles
    end

    roles_to_delete.each do |role|
      user.remove_role_from_another_role(role)
    end

    models = []

    roles.each do |role|
      case role
      when "admin"
        if current_user.has_role?(:admin)
          user.add_role :admin
        end
      else
        model_name, id = role.split "-"
        model_class = model_name.constantize
        model = model_class.find(id)

        case model
        when Institution
          # Disallow a user to give permissions over an institution if he isn't an institution admin
          institution_admin = current_user_roles.any? { |r| r.admin_of?(model) }
          next unless institution_admin

          user.add_role :admin, model
          user.add_role :member, model
        when Laboratory, Device
          institution = model.institution
          institution_admin = current_user_roles.any? { |r| r.admin_of?(institution) }
          model_admin = current_user_roles.any? { |r| r.admin_of?(model) }

          # Disallow a user to given permissions over a model if he isn't
          # that model's institution admin or that model's admin.
          next unless institution_admin || model_admin

          user.add_role :admin, model
          user.add_role :member, model
          user.add_role :member, model.institution
        when Location
          user.add_role :admin, model
          user.add_role :member, model
        else
          raise "Don't know how to set permissions for #{model}"
        end
      end
    end

    redirect_to users_path, notice: "Roles updated for #{user.email}"
  end
end
