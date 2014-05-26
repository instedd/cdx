class Policy < ActiveRecord::Base
  belongs_to :user

  serialize :definition, JSON
end
