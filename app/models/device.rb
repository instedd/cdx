class Device < ActiveRecord::Base
  resourcify

  belongs_to :device_model
  belongs_to :institution
  has_and_belongs_to_many :laboratories
  has_many :test_results

  before_create :set_key

  def set_key
    self.secret_key = Guid.new.to_s
  end

  def to_s
    name
  end
end
