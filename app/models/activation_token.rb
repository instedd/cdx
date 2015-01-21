class ActivationToken < ActiveRecord::Base
  belongs_to :device
  has_one :activation

  validates_presence_of :device, :client_id, :value

  before_validation :set_client_id, if: :new_record?
  before_validation :set_value, if: :new_record?


  def used?
    !activation.nil?
  end

  def use!(public_key)
    ActivationToken.transaction do
      device.ssh_keys.create!(public_key: public_key)
      self.activation = Activation.create!(activation_token: self)
    end
    SyncHelpers.client_settings(client_id)
  end

  def client_id_valid?
    SyncHelpers.client_id(device) == client_id
  end

  private

  def set_client_id
    self.client_id = SyncHelpers.client_id(device) if device && !self.client_id
  end

  def set_value
    self.value = Guid.new.to_s unless self.value
  end

end
