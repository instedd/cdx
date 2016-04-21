module CoreEntityId
  extend ActiveSupport::Concern

  included do
    # uniqness is not enforced since sample can share id
    before_create :ensure_entity_id
  end

  def ensure_entity_id
    write_attribute(:entity_id, read_attribute(:entity_id) || self.core_fields["id"])
  end

  def entity_id
    ensure_entity_id
    super
  end

  class_methods do
    def find_by_entity_id(entity_id, opts)
      find_by(entity_id: entity_id.to_s, institution_id: opts.fetch(:institution_id))
    end
  end
end
