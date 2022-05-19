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

  def self.entity_scope
    "sample"
  end

  attribute_field :isolate_name, copy: true
  attribute_field :specimen_role, copy: true
  attribute_field :old_batch_number, copy: true
  attribute_field :date_produced,
                  :lab_technician,
                  :inactivation_method,
                  :volume

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
end
