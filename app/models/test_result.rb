class TestResult < ApplicationRecord
  include AutoUUID
  include Entity
  include Resource
  include SiteContained

  NAME_FIELD = 'name'
  LAB_USER_FIELD = 'site_user'
  ASSAYS_FIELD = 'assays'
  START_TIME_FIELD = 'start_time'
  END_TIME_FIELD = 'end_time'

  has_and_belongs_to_many :device_messages
  has_many :test_result_parsed_data

  belongs_to :device, -> { with_deleted }
  belongs_to :sample_identifier, inverse_of: :test_results, autosave: true
  belongs_to :patient
  belongs_to :encounter

  has_many :alert_histories

  validates_presence_of :device
  # validates_uniqueness_of :test_id, scope: :device_id, allow_nil: true
  validate :same_patient_in_sample
  validate :validate_sample
  validate :validate_encounter
  validate :validate_patient

  before_create   :set_foreign_keys, prepend: true
  before_save   :set_entity_id
  after_destroy :destroy_from_index

  delegate :device_model, :device_model_id, to: :device
  delegate :sample, to: :sample_identifier, allow_nil: true

  def merge(test)
    super

    if test.is_a?(TestResult)
      self.sample_identifier = test.sample_identifier unless test.sample_identifier.blank?
      self.device_messages |= test.device_messages
      self.test_result_parsed_data << test.test_result_parsed_datum
    end

    self
  end

  def custom_fields_data
    data = {entity_scope => custom_fields}
    data = data.deep_merge(sample.entity_scope => sample.custom_fields) if sample
    data = data.deep_merge(patient.entity_scope => patient.custom_fields) if patient
    data
  end

  def self.supports_identifier?(key)
    key.blank?
  end

  def self.query params, user
    TestResultQuery.for params, user
  end

  def self.entity_scope
    "test"
  end

  def sample_identifiers
    sample.try(:sample_identifiers) || []
  end

  def entity_id
    core_fields['id']
  end

  def phantom?
    false
  end

  def test_result_parsed_datum
    test_result_parsed_data.last
  end

  def device=(value)
    super
    set_foreign_keys
  end

  def self.possible_results_for_assay
    entity_fields.detect { |f| f.name == 'assays' }.sub_fields.detect { |f| f.name == 'result' }.options
  end

  def as_json(json, localization_helper)
    json.(self, :uuid, :test_id)
    json.name self.core_fields[TestResult::NAME_FIELD]
    if self.sample
      json.sample_entity_ids self.sample.entity_ids
    end

    device_uuid = self.device.uuid
    json.start_time(localization_helper.format_datetime_device(self.core_fields[TestResult::START_TIME_FIELD], device_uuid))
    json.end_time(localization_helper.format_datetime_device(self.core_fields[TestResult::END_TIME_FIELD], device_uuid))

    json.assays (self.core_fields[TestResult::ASSAYS_FIELD] || [])

    if self.device.site
      json.site do
        json.name self.device.site.name
      end
    end

    json.device do
      json.name self.device.name
    end
  end

  def self.as_json_from_query(json, test_result_query_result, localization_helper)
    test = test_result_query_result["test"]
    json.uuid test["uuid"]
    json.name test["name"]
    json.assays test["assays"]
    json.test_id test["id"]

    json.sample_entity_ids test_result_query_result["sample"]["entity_id"]

    device_uuid = test_result_query_result["device"]["uuid"]
    json.start_time(localization_helper.format_datetime_device(test["start_time"], device_uuid))
    json.end_time(localization_helper.format_datetime_device(test["end_time"], device_uuid))

    json.site do
      json.name test_result_query_result["site"]["name"]
    end

    json.device do
      json.name test_result_query_result["device"]["name"]
    end
  end

  private

  def destroy_from_index
    TestResultIndexer.new(self).destroy
  end

  def same_patient_in_sample
    if self.sample && self.sample.patient != self.patient
      errors.add(:patient_id, "should match sample's patient")
    end
  end

  def set_foreign_keys
    self.site_id = device.try(:site_id)
    self.institution_id = device.try(:institution_id)
  end

  def set_entity_id
    self.test_id = entity_id unless entity_id.nil?
  end
end
