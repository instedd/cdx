class Prospect < ActiveRecord::Base
  validates :email, presence: true
end
