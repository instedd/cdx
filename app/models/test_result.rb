class TestResult < ActiveRecord::Base
  include AutoUUID
  include Entity

  NAME_FIELD = 'name'
  LAB_USER_FIELD = 'lab_user'
  ASSAYS_FIELD = 'assays'
  START_TIME_FIELD = 'start_time'

  has_and_belongs_to_many :device_messages
  belongs_to :device
  has_one :institution, through: :device
  has_one :laboratory, through: :device
  belongs_to :sample
  belongs_to :patient
  belongs_to :encounter
  validates_presence_of :device
  # validates_uniqueness_of :test_id, scope: :device_id, allow_nil: true
  validate :same_patient_in_sample

  delegate :device_model, :device_model_id, to: :device

  def merge(test)
    super

    if test.is_a?(TestResult)
      self.sample_id = test.sample_id unless test.sample_id.blank?
      self.device_messages |= test.device_messages
    end

    self
  end

  def pii_data
    pii = {entity_scope => plain_sensitive_data}
    pii = pii.deep_merge(sample.entity_scope => sample.plain_sensitive_data) if sample
    pii = pii.deep_merge(patient.entity_scope => patient.plain_sensitive_data) if patient
    pii
  end

  def custom_fields_data
    data = {entity_scope => custom_fields}
    data = data.deep_merge(sample.entity_scope => sample.custom_fields) if sample
    data = data.deep_merge(patient.entity_scope => patient.custom_fields) if patient
    data
  end

  def self.query params, user
    TestResultQuery.for params, user
  end

  def self.entity_scope
    "test"
  end

  private

  def same_patient_in_sample
    if self.sample && self.sample.patient != self.patient
      errors.add(:patient_id, "should match sample's patient")
    end
  end
end
