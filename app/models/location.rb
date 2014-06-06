class Location < ActiveRecord::Base
  include Resource

  acts_as_nested_set dependent: :destroy

  has_many :laboratories, dependent: :restrict_with_exception
  has_many :devices, :through => :laboratories
  has_many :events, :through => :laboratories

  def self.filter_by_owner(user)
    self
  end

  def filter_by_owner(user)
    self
  end
end
