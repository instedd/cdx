class UsersController < ApplicationController
  add_breadcrumb 'Users', :users_path

  before_filter { @in_users = true }

  expose(:users) { User.where("id != ?", current_user.id) }
  expose(:user)

  expose(:institutions) { current_user.institutions.includes(:laboratories, :devices).all }
  expose(:locations) { Location.roots }

  expose(:roles) { user.roles.all }

  def show
    add_breadcrumb user.email, user
  end

  def update
    roles = params[:roles] || []

    user.roles.destroy_all

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
        user.add_role :admin, model

        # TODO
        # if model.is_a?(Laboratory) || model.is_a?(Device)
        #   user.add_role :member, model.institution
        # end
      end
    end

    redirect_to users_path, notice: "Roles updated for #{user.email}"
  end
end
