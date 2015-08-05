module AutoUiHash
  extend ActiveSupport::Concern

  included do
    validates_uniqueness_of :entity_uid_hash, scope: :institution_id, allow_nil: true
    before_create :ensure_entity_uid_hash
  end

  def ensure_entity_uid_hash
    self.entity_uid_hash ||= MessageEncryption.hash(entity_uid.to_s) if entity_uid
  end

  module ClassMethods
    def find_by_pii(entity_uid, institution_id)
      find_by(entity_uid_hash: MessageEncryption.hash(entity_uid.to_s), institution_id: institution_id)
    end
  end
end
