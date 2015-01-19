class ActivationToken < ActiveRecord::Base
  belongs_to :device
  has_one :activation

  validates_presence_of :device, :device_secret_key, :value

  def available?
    activation.nil?
  end

  def used?
    !available?
  end


end
