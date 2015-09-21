class Institution < ActiveRecord::Base
  include AutoUUID
  include Resource

  belongs_to :user
  has_many :laboratories, dependent: :destroy
  has_many :devices, dependent: :destroy

  validates_presence_of :name

  after_create do |institution|
    user.grant_predefined_policy "owner", institution_id: institution.id
  end

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
end
