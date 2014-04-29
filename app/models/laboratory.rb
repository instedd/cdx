class Laboratory < ActiveRecord::Base
  resourcify

  belongs_to :institution
  has_one :user, through: :institution
  belongs_to :location
  has_and_belongs_to_many :devices
  has_many :test_results, through: :devices
end
