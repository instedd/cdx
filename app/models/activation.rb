class Activation < ActiveRecord::Base
  belongs_to :activation_token

  validates_presence_of :activation_token

  delegate :device_secret_key, to: :activation_token

  def settings
    {
      host: 'localhost', #TODO
      port: 2222, #TODO
      user: 'cdx-sync', #TODO
      inbox_dir: "sync/#{device_secret_key}/inbox", #TODO
      outbox_dir: "sync/#{device_secret_key}/outbox" #TODO
    }
  end
end
