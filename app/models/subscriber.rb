class Subscriber < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user
  validates_presence_of :name
  validates_presence_of :url
  validates_presence_of :filter
  validates_presence_of :fields
end
