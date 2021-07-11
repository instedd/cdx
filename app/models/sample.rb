class Sample < ActiveRecord::Base
  include Entity

  belongs_to :institution
  belongs_to :patient
  belongs_to :encounter
  belongs_to :batch

  has_many :sample_identifiers, inverse_of: :sample, dependent: :destroy
  has_many :test_results, through: :sample_identifiers

  has_many :notes
  accepts_nested_attributes_for :notes, allow_destroy: true

  validates_presence_of :institution
  validate :validate_encounter
  validate :validate_patient

  def self.entity_scope
    "sample"
  end

  attribute_field :isolate_name,
                  :is_quality_control,
                  :inactivation_method,
                  :volume,
                  :lab_technician,
                  :production_date

  INACTIVATION_METHOD_VALUES = entity_fields.detect { |f| f.name == 'inactivation_method' }.options
  # validates_inclusion_of :inactivation_method, in: INACTIVATION_METHOD_VALUES, message: "is not within valid options (should be one of #{INACTIVATION_METHOD_VALUES.join(', ')})"
  # validates_presence_of :isolate_name
  # validates_numericality_of :volume, greater_than: 0, message: "value must be greater than 0"
  # validates_presence_of :lab_technician

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

  def new_notes=(notes_list = [])
    notes_list.each do |note|
      notes.build(
        description: note[:description],
        user: note[:user],
        )
    end
  end
end
