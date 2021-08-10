class Sample < ActiveRecord::Base
  include Entity

  belongs_to :institution
  belongs_to :patient
  belongs_to :encounter
  belongs_to :batch

  has_many :sample_identifiers, inverse_of: :sample, dependent: :destroy
  has_many :test_results, through: :sample_identifiers

  has_many :notes, dependent: :destroy
  accepts_nested_attributes_for :notes, allow_destroy: true

  has_many :assay_attachments, dependent: :destroy
  accepts_nested_attributes_for :assay_attachments, allow_destroy: true

  validates_presence_of :institution
  validate :validate_encounter
  validate :validate_patient

  def self.entity_scope
    "sample"
  end
  attribute_field :isolate_name, copy: true
  attribute_field :date_produced,
                  :lab_technician,
                  :specimen_role,
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

  def is_quality_control
    specimen_role == 'Q - Control specimen'
  end

  def new_assays=(new_assays = [])
    new_assays.each do |assay|
      loinc_code_id = if assay[:loinc_code_id].empty?
                        nil
                      else
                        assay[:loinc_code_id]
                      end
      assay_attachments.build(
        picture: assay[:file],
        loinc_code: LoincCode.find(loinc_code_id),
        result: assay[:result],
        sample: self
      )
    end
  end

  def new_notes=(notes_list = [])
    notes_list.each do |note|
      notes.build(
        description: note[:description],
        user: note[:user],
        sample: self
      )
    end
  end

  def date_produced_description
    if date_produced.is_a?(Time)
      return date_produced.strftime(I18n.t('date.input_format.pattern'))
    end

    date_produced
  end
end
