class Encounter < ActiveRecord::Base
  include Entity
  include AutoUUID
  include Resource
  include SiteContained

  ASSAYS_FIELD = 'diagnosis'
  OBSERVATIONS_FIELD = 'observations'

  has_many :samples, dependent: :restrict_with_error
  has_many :test_results, dependent: :restrict_with_error

  belongs_to :patient
  belongs_to :user

  validates_presence_of :site, if: Proc.new { |encounter| encounter.institution && !encounter.institution.kind_manufacturer? }

  validate :validate_patient

  before_save :ensure_entity_id

  def self.entity_scope
    "encounter"
  end

  attribute_field :start_time, copy: true

  attr_accessor :new_samples # Array({entity_id: String}) of new generated samples from UI.

  def entity_id
    core_fields["id"]
  end

  def has_entity_id?
    entity_id.not_nil?
  end

  def phantom?
    super && core_fields[ASSAYS_FIELD].blank? && plain_sensitive_data[OBSERVATIONS_FIELD].blank?
  end

  def self.merge_assays(assays1, assays2)
    return assays2 unless assays1
    return assays1 unless assays2

    assays1.dup.tap do |res|
      assays2.each do |assay2|
        assay = res.find { |a| a["condition"] == assay2["condition"] }
        if assay.nil?
          res << assay2.dup
        else
          assay.merge! assay2 do |key, v1, v2|
            if key == "result"
              if v1 == v2
                v1
              elsif v1 == "indeterminate" || v1.blank? || (v1 == "n/a" && v2 != "indeterminate")
                v2
              elsif v2 == "indeterminate" || v2.blank? || (v2 == "n/a" && v1 != "indeterminate")
                v1
              else
                "indeterminate"
              end
            else
              v1
            end
          end
        end
      end
    end
  end

  def self.merge_assays_without_values(assays1, assays2)
    return assays2 unless assays1
    return assays1 unless assays2

    assays1.dup.tap do |res|
      assays2.each do |assay2|
        assay = res.find { |a| a["condition"] == assay2["condition"] }
        if assay.nil?
          res << (assay2.dup.tap do |h|
            h["result"] = nil
          end)
        end
      end
    end
  end

  def self.entity_scope
    "encounter"
  end

  def self.find_by_entity_id(entity_id, opts)
    find_by(entity_id: entity_id.to_s, institution_id: opts.fetch(:institution_id))
  end

  def self.query params, user
    EncounterQuery.for params, user
  end

  def test_results_not_in_diagnostic
    diagnostic.present? ? test_results.where("updated_at > ?", self.user_updated_at || self.created_at) : test_results
  end

  def diagnostic
    core_fields[Encounter::ASSAYS_FIELD]
  end

  def human_diagnose
    return unless diagnostic

    positives = diagnostic.select {|a| a['result'] == 'positive'}.map { |a| a['condition'].try(:upcase) }.to_a
    negatives = diagnostic.select {|a| a['result'] == 'negative'}.map { |a| a['condition'].try(:upcase) }.to_a

    res = ""
    res << positives.join(', ')
    unless positives.empty?
      res << " detected. "
    end
    res << negatives.join(', ')
    unless negatives.empty?
      res << " not detected. "
    end

    res.strip
  end

  attribute_field OBSERVATIONS_FIELD

  def has_dirty_diagnostic?
    test_results_not_in_diagnostic.count > 0
  end

  def updated_diagnostic
    assays_to_merge = test_results_not_in_diagnostic\
      .map{|tr| tr.core_fields[TestResult::ASSAYS_FIELD]}

    assays_to_merge.inject(diagnostic) do |merged, to_merge|
      Encounter.merge_assays_without_values(merged, to_merge)
    end
  end

  def updated_diagnostic_timestamp!
    update_attribute(:user_updated_at, Time.now.utc)
  end

  def self.as_json_from_query(json, encounter_query_result, localization_helper)
    encounter = encounter_query_result["encounter"]

    json.encounter do
      json.uuid encounter["uuid"]
      json.diagnosis encounter["diagnosis"] || []
      json.start_time(localization_helper.format_datetime(encounter["start_time"]))
      json.end_time(localization_helper.format_datetime(encounter["end_time"]))
    end

    json.site do
      json.name encounter_query_result["site"]["name"]
    end
  end

  protected

  def ensure_entity_id
    self.entity_id = entity_id
  end

end
