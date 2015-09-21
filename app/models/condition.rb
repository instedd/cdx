class Condition < ActiveRecord::Base
  has_and_belongs_to_many :manifests
  validates_uniqueness_of :name

  def self.valid_name?(name)
    name =~ /\A[a-z][a-z0-9_]*\Z/
  end
end
