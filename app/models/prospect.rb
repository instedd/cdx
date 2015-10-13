class Prospect < ActiveRecord::Base
  before_create :set_uuid
  validates :email, presence: true

  def to_param
    uuid
  end

  private

  def set_uuid
    self.uuid = ::SecureRandom.uuid
  end
end
