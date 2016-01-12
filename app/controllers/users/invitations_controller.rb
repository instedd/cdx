class Users::InvitationsController < Devise::InvitationsController
  def accept_resource
    resource = resource_class.accept_invitation!(update_resource_params)
    resource.confirm!
    resource
  end
end
