class WorkGroup < ActiveRecord::Base
  belongs_to :user
  has_many :subscribers
  has_many :facilities
end
