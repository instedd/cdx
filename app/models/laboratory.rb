class Laboratory < ActiveRecord::Base
  belongs_to :institution
  belongs_to :location
  has_many :devices, dependent: :restrict
  has_many :test_results, through: :devices
end
