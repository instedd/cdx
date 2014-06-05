class Location < ActiveRecord::Base
  include Resource

  acts_as_nested_set dependent: :destroy

  has_many :laboratories, dependent: :restrict_with_exception
  has_many :devices, :through => :laboratories
  has_many :events, :through => :laboratories
end
