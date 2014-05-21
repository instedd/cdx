class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :confirmable, :omniauthable,
         :lockable

  has_many :identities
  has_many :institutions
  has_many :laboratories, through: :institutions
  has_many :devices, through: :institutions
  has_many :subscribers

  def superadmin?
    has_role? :admin
  end

  def visible_institutions
    Institution.with_role(:member, self)
  end

  def create(model)
    if model.respond_to?(:user=)
      model.user = self
    end
    if (status = model.save)
      add_role :admin, model
      add_role :member, model
    end
    status
  end

  def remove_role_from_another_role(role)
    if role.resource_id
      remove_role role.name, role.resource
    else
      remove_role role.name
    end
  end
end
