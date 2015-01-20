class Activation < ActiveRecord::Base
  belongs_to :activation_token

  validates_presence_of :activation_token

  delegate :device_secret_key, to: :activation_token

  def settings
    SyncHelpers.client_settings(device_secret_key)
  end
end
