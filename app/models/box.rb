class Box < ApplicationRecord
  include AutoUUID
  # include Entity
  include Resource
  include SiteContained

  has_many :samples, dependent: :nullify, autosave: true
  has_many :batches, dependent: :nullify, autosave: true

  # def self.entity_scope
  #   "box"
  # end
end
