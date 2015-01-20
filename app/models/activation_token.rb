class ActivationToken < ActiveRecord::Base
  belongs_to :device
  has_one :activation

  validates_presence_of :device, :device_secret_key, :value

  before_validation :set_device_secret_key, if: :new_record?

  def used?
    !activation.nil?
  end

  def use!(public_key)
    ActivationToken.transaction do
      device.ssh_keys.create!(public_key: public_key)
      self.activation = Activation.create!(activation_token: self)
    end
    SyncHelpers.client_settings(device_secret_key)
  end

  def device_secret_key_valid?
    device.secret_key == device_secret_key
  end

  private

  def set_device_secret_key
    self.device_secret_key = device.secret_key if device && !self.device_secret_key
  end
end
