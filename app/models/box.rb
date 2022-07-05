class Box < ApplicationRecord
  def self.institution_is_required
    false
  end

  include AutoUUID
  include Entity
  include Resource
  include SiteContained

  has_many :samples, dependent: :nullify, autosave: true
  has_many :batches, -> { distinct.order("samples.id ASC") }, through: :samples

  has_many :box_transfers

  scope :autocomplete, ->(uuid) {
          if uuid.size == 36
            # Full UUID
            where(uuid: uuid)
          else
            # Partial UUID
            where("uuid LIKE concat(?, '%')", uuid)
          end
        }

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

  def build_samples(batch, concentration_exponents:, replicates:, media:)
    concentration_exponents.each do |exponent|
      1.upto(replicates) do |replicate|
        samples << batch.build_sample(
          concentration_number: 1,
          concentration_exponent: exponent,
          replicate: replicate,
          institution: institution,
          site: site,
          media: media,
        )
      end
    end
  end

  # Returns the list of samples with a stable order that isn't the original
  # creation date or the sample's auto-incremented id.
  def scrambled_samples
    samples.joins(:sample_identifiers).order("uuid")
  end

  def attach_qc_info
    samples.each do |sample|
      sample.attach_qc_info
      sample.save!
    end
  end

  def detach_from_context
    assign_attributes(
      site: nil,
      institution: nil
    )
    samples.each do |sample|
      sample.detach_from_context
      sample.save!
    end
  end

  # Returns the full list of sample attributes that can be blinded.
  def self.blind_attribute_names
    %i[batch_number concentration concentration_formula replicate virus_lineage isolate_name]
  end

  # Returns the list of sample attributes that should be blinded for the box'
  def blind_attributes
    %i[batch_number concentration concentration_formula replicate virus_lineage isolate_name]
  end

  # Returns true if a sample attribute should be blinded for the current box.
  def blind_attribute?(attr_name)
    blind_attributes.include?(attr_name)
  end
end
