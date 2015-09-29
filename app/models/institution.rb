class Institution < ActiveRecord::Base
  include AutoUUID
  include Resource

  belongs_to :user

  has_many :laboratories, dependent: :destroy
  has_many :devices, dependent: :destroy
  has_many :device_models, dependent: :restrict_with_error
  has_many :encounters, dependent: :destroy

  validates_presence_of :name

  after_create :grant_owner_policy

  def self.filter_by_owner(user, check_conditions)
    if check_conditions
      where(user_id: user.id)
    else
      self
    end
  end

  def filter_by_owner(user, check_conditions)
    user_id == user.id ? self : nil
  end

  def to_s
    name
  end

  private

  def grant_owner_policy
    user.grant_predefined_policy "owner", institution_id: self.id
  end

end
