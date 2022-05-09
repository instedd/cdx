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

  validates_presence_of :purpose
  validates_inclusion_of :purpose, in: ->(_) { Box.purposes }
  validates_associated :samples

  def self.purposes
    entity_fields.find { |f| f.name == 'purpose' }.options
  end

  def build_samples(batch, exponents:, replicas:)
    exponents.each do |exponent|
      1.upto(replicas) do |replica|
        batch.samples.build.tap do |sample|
          sample.institution_id = batch.institution_id
          sample.site_id = batch.site_id
          sample.isolate_name = batch.isolate_name
          sample.inactivation_method = batch.inactivation_method
          # sample.concentration = 10 ** -exponent
          # sample.replica = replica
          samples << sample
        end
      end
    end
  end
end
