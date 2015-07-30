class TestResult < ActiveRecord::Base
  include AutoUUID
  include Entity

  has_and_belongs_to_many :device_messages
  belongs_to :device
  has_one :institution, through: :device
  belongs_to :sample
  belongs_to :patient
  belongs_to :encounter
  validates_presence_of :device
  validates_uniqueness_of :test_id, scope: :device_id, allow_nil: true
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
    pii = self.plain_sensitive_data
    pii = pii.deep_merge(self.sample.plain_sensitive_data) if self.sample
    pii = pii.deep_merge(self.patient.plain_sensitive_data) if self.patient
    pii
  end

  def custom_fields_data
    data = self.custom_fields
    data = data.deep_merge(self.sample.custom_fields) if self.sample
    data = data.deep_merge(self.patient.custom_fields) if self.patient
    data
  end

  def self.query params, user
    TestResultQuery.new params, user
  end

  private

  def same_patient_in_sample
    if self.sample && self.sample.patient != self.patient
      errors.add(:patient_id, "should match sample's patient")
    end
  end
end
