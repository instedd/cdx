class Laboratory < ActiveRecord::Base
  belongs_to :institution
  has_one :user, through: :institution
  belongs_to :location
  has_and_belongs_to_many :devices
  has_many :events, through: :devices

  validates_presence_of :institution
  validates_presence_of :name

  def self.filter_by_owner(user)
    joins(:institution).where(institutions: {user_id: user.id})
  end

  def filter_by_owner(user)
    institution.user_id == user.id ? self : nil
  end

  def to_s
    name
  end
end
