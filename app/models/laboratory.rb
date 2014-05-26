class Laboratory < ActiveRecord::Base
  belongs_to :institution
  has_one :user, through: :institution
  belongs_to :location
  has_and_belongs_to_many :devices
  has_many :test_results, through: :devices

  def to_s
    name
  end
end
