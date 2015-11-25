class Role < ActiveRecord::Base
  belongs_to :instution
  belongs_to :site
  belongs_to :policy
  has_and_belongs_to_many :users
end
