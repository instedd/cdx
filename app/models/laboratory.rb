class Laboratory < ActiveRecord::Base
  belongs_to :institution
  has_one :user, through: :institution
  belongs_to :location
  has_many :devices, dependent: :restrict_with_exception
  has_many :test_results, through: :devices
end
