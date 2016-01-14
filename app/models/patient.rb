class Patient < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoIdHash
  include Resource

  belongs_to :institution

  has_many :test_results, dependent: :restrict_with_error
  has_many :samples, dependent: :restrict_with_error
  has_many :encounters, dependent: :restrict_with_error

  validates_presence_of :institution

  def has_entity_id?
    entity_id_hash.not_nil?
  end

  def self.entity_scope
    "patient"
  end

  attribute_field :name, copy: true
  attribute_field :entity_id, field: :id, copy: true
  attribute_field :gender, :dob, :email, :phone

end
