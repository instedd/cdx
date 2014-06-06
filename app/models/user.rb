class User < ActiveRecord::Base
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
  has_many :policies
  has_many :granted_policies, class_name: "Policy", foreign_key: "granter_id"

  after_create :grant_implicit_policy

  def create(model)
    if model.respond_to?(:user=)
      model.user = self
    end
    model.save ? model : nil
  end

  private

  def grant_implicit_policy
    implicit = Policy.implicit
    implicit.granter = nil
    implicit.user = self
    implicit.save(validate: false)
  end

  def grant_superadmin_policy
    implicit = Policy.superadmin
    implicit.granter = nil
    implicit.user = self
    implicit.save(validate: false)
  end
end
