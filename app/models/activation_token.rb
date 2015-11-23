class ActivationToken < ActiveRecord::Base
  belongs_to :device
  has_one :activation, dependent: :destroy

  validates_uniqueness_of :device_id
  validates_presence_of :device, :client_id, :value

  before_validation :set_client_id, if: :new_record?
  before_validation :set_value, if: :new_record?


  def used?
    !activation.nil?
  end

  def use!(public_key)
    ActivationToken.transaction do
      device.ssh_key = SshKey.create!(public_key: public_key, device: device)
      self.activation = Activation.create!(activation_token: self)
      SshKey.regenerate_authorized_keys!
    end
    device.set_key_for_activation_token
    device.save!
    settings = SyncHelpers.client_settings(client_id, device.uuid, device.plain_secret_key)
    destroy
    settings
  end

  private

  def set_client_id
    self.client_id = SyncHelpers.client_id(device) if device && !self.client_id
  end

  def set_value
    self.value = Guid.new.to_s unless self.value
  end
end
