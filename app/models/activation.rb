class Activation < ActiveRecord::Base
  belongs_to :activation_token

  validates_presence_of :activation_token
end
