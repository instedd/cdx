class Prospect < ActiveRecord::Base
  before_create :set_uuid
  validates :email, presence: true

  scope :pending, -> { where.not(uuid: nil) }

  def to_param
    uuid
  end

  private

  def set_uuid
    self.uuid = ::SecureRandom.uuid
  end
end
