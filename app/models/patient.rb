class Patient < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoIdHash
  include Resource
  include DateDistanceHelper
  include WithLocation
  include SiteContained

  has_many :test_results, dependent: :restrict_with_error
  has_many :samples, dependent: :restrict_with_error
  has_many :encounters, dependent: :restrict_with_error

  validates_presence_of :institution
  validates_uniqueness_of :entity_id, scope: :institution_id, allow_nil: true
  validate :entity_id_not_changed

  scope :within, -> (institution_or_site, exclude_subsites = false) {
    if institution_or_site.is_a?(Institution)
      if exclude_subsites
        where(institution: institution_or_site, site: nil)
      else
        where(institution: institution_or_site)
      end
    elsif exclude_subsites
      where("site_id = ? OR id in (#{Encounter.within(institution_or_site, true).select(:patient_id).to_sql})", institution_or_site)
    else
      where("site_prefix LIKE concat(?, '%') OR id in (#{Encounter.within(institution_or_site).select(:patient_id).to_sql})", institution_or_site.prefix)
    end
  }

  def has_entity_id?
    entity_id_hash.not_nil?
  end

  def self.entity_scope
    "patient"
  end

  attribute_field :name, copy: true
  attribute_field :entity_id, field: :id, copy: true
  attribute_field :gender, :dob, :email, :phone

  def age
    years_between Time.parse(dob), Time.now rescue nil
  end

  def age_months
    months_between Time.parse(dob), Time.now rescue nil
  end


  def dob_description(date_pattern)
    if dob && (dob_time = self.dob_time)
      "#{dob_time.strftime(date_pattern)} (#{age} y/o)"
    else
      ""
    end
  end

  def last_encounter
    @last_encounter || encounters.order(start_time: :desc).first.try(&:start_time)
  end

  def last_encounter=(value)
    @last_encounter = value
  end

  def self.preload_last_encounter!
    last_encounter_by_patient_id = Hash[Encounter.where(patient_id: all.pluck(:id)).group("patient_id").pluck("patient_id, max(start_time)")]
    all.to_a.each do |record|
      record.last_encounter = last_encounter_by_patient_id[record.id]
    end
  end

  def as_json_card(json)
    json.(self, :id, :name, :age, :age_months, :gender, :address, :phone, :email, :entity_id)
    json.dob dob_time.try { |d| d.strftime(I18n.t('date.input_format.pattern')) }
  end

  def name_or_unknown
    name || "(Unknown name)"
  end

  def dob_time
    Time.parse(dob) rescue nil
  end

  private

  def entity_id_not_changed
    if entity_id_changed? && self.persisted? && entity_id_was.present?
      errors.add(:entity_id, "can't be changed after assigned")
    end
  end
end
