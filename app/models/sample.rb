class Sample < ApplicationRecord
  def self.institution_is_required
    false
  end

  include Entity
  include Resource
  include SpecimenRole
  include InactivationMethod
  include SiteContained
  include DateProduced

  belongs_to :patient
  belongs_to :encounter
  belongs_to :batch
  belongs_to :box
  belongs_to :qc_info

  has_many :sample_identifiers, inverse_of: :sample, dependent: :destroy
  has_many :test_results, through: :sample_identifiers
  has_many :sample_transfers, dependent: :destroy

  has_many :assay_attachments, dependent: :destroy
  accepts_nested_attributes_for :assay_attachments, allow_destroy: true
  validates_associated :assay_attachments, message: "are invalid"

  has_many :notes, dependent: :destroy
  accepts_nested_attributes_for :notes, allow_destroy: true
  validates_associated :notes, message: "are invalid"

  validate :validate_encounter
  validate :validate_patient

  validates_numericality_of :concentration_number, only_integer: true, greater_than: 0, allow_blank: true
  validates_numericality_of :concentration_exponent, only_integer: true, greater_than: 0, allow_blank: true
  validates_numericality_of :replicate, only_integer: true, greater_than_or_equal_to: 0, allow_blank: true
  validates_inclusion_of :media, in: ->(_) { Sample.medias }, allow_blank: true
  validate :validate_box_context, if: -> { box.present? }

  def validate_box_context
    errors.add(:institution, "must be the same as the box it is contained in") unless institution == box.institution
    errors.add(:site, "must be the same box it is contained in") unless site == box.site
  end

  def self.entity_scope
    "sample"
  end

  attribute_field :isolate_name, copy: true
  attribute_field :specimen_role, copy: true
  attribute_field :old_batch_number, copy: true
  attribute_field :date_produced,
                  :lab_technician,
                  :inactivation_method,
                  :volume,
                  :virus_lineage,
                  :concentration_number,
                  :concentration_exponent,
                  :replicate,
                  :media

  def self.find_by_entity_id(entity_id, opts)
    query = joins(:sample_identifiers).where(sample_identifiers: {entity_id: entity_id.to_s}, institution_id: opts.fetch(:institution_id))
    query = query.where(sample_identifiers: {site_id: opts[:site_id]}) if opts[:site_id]
    query.first
  end

  def self.find_all_by_any_uuid(uuids)
    joins(:sample_identifiers).where(sample_identifiers: {uuid: uuids})
  end

  scope :autocomplete, ->(uuid) {
          if uuid.size == 36
            # Full UUID
            find_all_by_any_uuid(uuid)
          else
            # Partial UUID
            joins(:sample_identifiers).where("sample_identifiers.uuid LIKE concat(?, '%')", uuid)
          end
        }

  def self.medias
    entity_fields.find { |f| f.name == 'media' }.options
  end

  def merge(other_sample)
    # Adds all sample_identifiers from other_sample if they have an uuid (ie they have been persisted)
    # or if they contain a new entity_id (ie not already in this sample.sample_identifiers)
    super
    self.sample_identifiers += other_sample.sample_identifiers.reject do |other_identifier|
      other_identifier.uuid.blank? && self.sample_identifiers.any? { |identifier| identifier.entity_id == other_identifier.entity_id }
    end
    self
  end

  def uuid=(value)
    # dummy setter needed by SampleForm
  end

  def uuid
    uuids.sort.first
  end

  def partial_uuid
    uuid.to_s[0..-5]
  end

  def entity_ids
    self.sample_identifiers.map(&:entity_id)
  end

  def uuids
    self.sample_identifiers.map(&:uuid)
  end

  def empty_entity?
    super && entity_ids.compact.empty?
  end

  def has_entity_id?
    entity_ids.compact.any?
  end

  def batch_number
    old_batch_number || batch.try(&:batch_number)
  end

  def has_qc_reference?
    !!(qc_info || (batch && batch.has_qc_sample?))
  end

  # Removes sample from its context when getting transferred.
  # It's added to the destination context when confirmed.
  def detach_from_context
    assign_attributes(
      batch: nil,
      old_batch_number: batch.try(:batch_number),
      site: nil,
      institution: nil
    )
  end

  def attach_qc_info
    if qc_info = batch.try(&:qc_info)
      self.qc_info = qc_info
    end
  end

  # Attribute fields don't convert numerical types.
  %w[concentration_number concentration_exponent replicate].each do |name|
    define_method name do
      core_fields[name].presence.try(&:to_i)
    end
  end

  def concentration
    if (n = concentration_number) && (e = concentration_exponent)
      n * (10 ** -e)
    end
  end

  def concentration_formula
    if (n = concentration_number) && (e = concentration_exponent)
      if n == 1
        "10E-#{e}"
      else
        "#{n} × 10E-#{e}"
      end
    end
  end
end
