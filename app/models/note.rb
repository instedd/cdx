class Note < ActiveRecord::Base
  belongs_to :sample
  belongs_to :user

  validates_presence_of :user
  validates_presence_of :sample
  validates_presence_of :description
end
