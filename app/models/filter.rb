class Filter < ActiveRecord::Base
  belongs_to :user
  serialize :params, JSON
end
