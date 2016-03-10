module AutoUUID
  extend ActiveSupport::Concern

  included do
    after_initialize :generate_uuid
  end

private

  def generate_uuid
    self.uuid ||= Guid.new.to_s
  end
end
