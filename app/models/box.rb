class Box < ApplicationRecord
  include AutoUUID
  include Entity
  include Resource
  include SiteContained

  has_many :samples, dependent: :nullify, autosave: true
  has_many :batches, -> { distinct.order("samples.id ASC") }, through: :samples

  def self.entity_scope
    "box"
  end

  attribute_field :purpose, copy: true

  validates_presence_of :purpose
  validates_inclusion_of :purpose, in: ->(_) { Box.purposes }
  validates_associated :samples

  scope :count_samples, -> {
    select("boxes.*, COUNT(samples.id) AS samples_count")
      .joins(:samples)
      .group("samples.box_id")
  }

  def self.purposes
    entity_fields.find { |f| f.name == 'purpose' }.options
  end

  def build_samples(batch, exponents:, replicas:)
    exponents.each do |exponent|
      1.upto(replicas) do |replica|
        samples << batch.build_sample(
          # concentration_number: 1,
          # concentration_exponent: 10 ** -exponent,
          # replica: replica,
        )
      end
    end
  end

  # Returns the list of samples with a stable order that isn't the original
  # creation date or the sample's auto-incremented id.
  def scrambled_samples
    samples.joins(:sample_identifiers).order("uuid")
  end
end
