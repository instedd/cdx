class Note < ApplicationRecord
  belongs_to :user
  belongs_to :sample, :touch => true

  validates_presence_of :user
  validates_presence_of :description
end
