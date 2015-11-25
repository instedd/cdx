class RolesController < ApplicationController
  def index
    @roles = Role.all
  end

  def new
    @role = Role.new
    # FIXME: review permissions
    @institutions = check_access(Institution, READ_INSTITUTION)
    @sites = check_access(Site, READ_SITE)
    @users = User.all
  end
end
