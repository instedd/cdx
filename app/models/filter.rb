class Filter < ActiveRecord::Base
  belongs_to :user
  serialize :params, JSON

  validates_presence_of :user
  validates_presence_of :name
  validates_presence_of :params
end
