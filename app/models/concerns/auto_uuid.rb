module AutoUUID
  extend ActiveSupport::Concern

  included do
    before_create :generate_uuid
  end

private

  def generate_uuid
    self.uuid ||= Guid.new.to_s
  end
end