class Note < ApplicationRecord
  belongs_to :user

  validates_presence_of :user
  validates_presence_of :description
end
