class ActivationToken < ActiveRecord::Base
  belongs_to :device
  has_one :activation

  validates_presence_of :device, :device_secret_key, :value

  before_validation :set_device_secret_key, if: :new_record?

  def used?
    !activation.nil?
  end

  def use!
    Activation.create!(activation_token: self) unless used?
  end

  private

  def set_device_secret_key
    self.device_secret_key = device.secret_key if device
  end
end
