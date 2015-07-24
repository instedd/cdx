class Condition < ActiveRecord::Base
  has_and_belongs_to_many :manifests
  validates_uniqueness_of :name
end
