class Filter < ActiveRecord::Base
  belongs_to :user
  serialize :query, JSON

  validates_presence_of :user
  validates_presence_of :name
  validates_presence_of :query
end
