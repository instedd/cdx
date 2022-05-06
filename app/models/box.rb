class Box < ApplicationRecord
  include AutoUUID
  include Entity
  include Resource
  include SiteContained

  has_many :samples, dependent: :nullify, autosave: true
  has_many :batches, through: :samples

  def self.entity_scope
    "box"
  end

  attribute_field :purpose

  def self.purposes
    entity_fields.find { |f| f.name == 'purpose' }.options
  end
end
