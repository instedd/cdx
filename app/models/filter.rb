class Filter < ActiveRecord::Base
  belongs_to :user
  has_many :subscribers, ->(f) { where user_id: f.user_id }
  serialize :query, JSON

  validates_presence_of :user
  validates_presence_of :name
  validates_presence_of :query
end
