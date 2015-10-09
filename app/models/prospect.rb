class Prospect < ActiveRecord::Base
  before_create :set_uuid
  validates :email, presence: true

  private
  def set_uuid
    self.uuid = ::SecureRandom.uuid
  end
end
