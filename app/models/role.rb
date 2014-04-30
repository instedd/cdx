class Role < ActiveRecord::Base
  has_and_belongs_to_many :users, :join_table => :users_roles
  belongs_to :resource, :polymorphic => true

  scopify

  def superadmin?
    name == "admin" && !resource_id
  end

  def admin_of?(resource)
    resource_type == resource.class.name && resource_id == resource.id && name == "admin"
  end
end
