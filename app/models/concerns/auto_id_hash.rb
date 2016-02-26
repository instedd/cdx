module AutoIdHash
  extend ActiveSupport::Concern

  included do
    validates_uniqueness_of :entity_id_hash, scope: :institution_id, allow_nil: true
    before_validation :ensure_entity_id_hash
  end

  def ensure_entity_id_hash
    self.entity_id_hash ||= MessageEncryption.hash(entity_id.to_s) if entity_id
  end

  class_methods do
    def find_by_entity_id(entity_id, opts={})
      find_by(entity_id_hash: MessageEncryption.hash(entity_id.to_s), institution_id: opts.fetch(:institution_id))
    end
  end
end
