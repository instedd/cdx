class Institution < ActiveRecord::Base
  include Resource
  belongs_to :user
  has_many :laboratories, dependent: :destroy
  has_many :devices, dependent: :destroy
  validates_presence_of :name

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

  def elasticsearch_index_name
    "#{Cdx::Api.index_prefix}_#{id}"
  end
end
