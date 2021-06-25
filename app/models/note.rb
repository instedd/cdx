class Note < ActiveRecord::Base
  belongs_to :laboratory_sample
  belongs_to :user

  validates_presence_of :user
  validates_presence_of :laboratory_sample
  validates_presence_of :description
end
