class Event < ActiveRecord::Base
  has_and_belongs_to_many :device_events
  belongs_to :device
  has_one :institution, through: :device
  belongs_to :sample
  belongs_to :patient
  serialize :custom_fields
  serialize :indexed_fields
  validates_presence_of :device
  validates_uniqueness_of :event_id, scope: :device_id, allow_nil: true

  before_create :generate_uuid
  before_save :encrypt

  after_initialize do
    self.custom_fields  ||= {}
    self.indexed_fields  ||= {}
  end

  attr_writer :plain_sensitive_data

  delegate :device_model, :device_model_id, to: :device

  def merge(event)
    self.plain_sensitive_data.deep_merge_not_nil!(event.plain_sensitive_data)
    self.custom_fields.deep_merge_not_nil!(event.custom_fields)
    self.indexed_fields.deep_merge_not_nil!(event.indexed_fields)
    self.sample_id = event.sample_id unless event.sample_id.blank?
    self.device_events |= event.device_events
    self
  end

  def add_sample_data(sample)
    if sample.plain_sensitive_data.present?
      self.plain_sensitive_data[:sample] ||= {}
      self.plain_sensitive_data[:sample].deep_merge_not_nil!(sample.plain_sensitive_data)
    end

    if sample.custom_fields.present?
      self.custom_fields[:sample] ||= {}
      self.custom_fields[:sample].deep_merge_not_nil!(sample.custom_fields)
    end

    if sample.indexed_fields.present?
      self.indexed_fields[:sample] ||= {}
      self.indexed_fields[:sample].deep_merge_not_nil!(sample.indexed_fields)
    end
  end

  def extract_sample_data_into(sample)
    if self.patient_id.present?
      sample.patient_id = self.patient_id
      self.patient_id = nil
    end

    sample.plain_sensitive_data.reverse_deep_merge! (self.plain_sensitive_data[:sample] || {})
    sample.custom_fields.reverse_deep_merge! (self.custom_fields[:sample] || {})
    sample.indexed_fields.reverse_deep_merge! (self.indexed_fields[:sample] || {})

    if self.plain_sensitive_data[:patient].present?
      sample.plain_sensitive_data[:patient] ||= {}
      sample.plain_sensitive_data[:patient].reverse_deep_merge! self.plain_sensitive_data[:patient]
    end

    if self.custom_fields[:patient].present?
      sample.custom_fields[:patient] ||= {}
      sample.custom_fields[:patient].reverse_deep_merge! self.custom_fields[:patient]
    end

    if self.indexed_fields[:patient].present?
      sample.indexed_fields[:patient] ||= {}
      sample.indexed_fields[:patient].reverse_deep_merge! self.indexed_fields[:patient]
    end

    self.plain_sensitive_data.delete(:sample)
    self.custom_fields.delete(:sample)
    self.indexed_fields.delete(:sample)
    self.plain_sensitive_data.delete(:patient)
    self.custom_fields.delete(:patient)
    self.indexed_fields.delete(:patient)
  end

  def add_patient_data(patient)
    if self.sample.present?
      self.sample.add_patient_data(patient)
      # TODO check if this can be moved to autosave
      self.sample.save!
    else
      if patient.plain_sensitive_data.present?
        self.plain_sensitive_data[:patient] ||= {}
        self.plain_sensitive_data[:patient].deep_merge_not_nil!(patient.plain_sensitive_data)
      end

      if patient.custom_fields.present?
        self.custom_fields[:patient] ||= {}
        self.custom_fields[:patient].deep_merge_not_nil!(patient.custom_fields)
      end

      if patient.indexed_fields.present?
        self.indexed_fields[:patient] ||= {}
        self.indexed_fields[:patient].deep_merge_not_nil!(patient.indexed_fields)
      end
    end
  end

  def extract_patient_data_into(patient)
    if self.sample.present?
      self.sample.extract_patient_data_into(patient)
    else
      patient.plain_sensitive_data.reverse_deep_merge! (self.plain_sensitive_data[:patient] || {})
      patient.custom_fields.reverse_deep_merge! (self.custom_fields[:patient] || {})
      patient.indexed_fields.reverse_deep_merge! (self.indexed_fields[:patient] || {})

      self.plain_sensitive_data.delete(:patient)
      self.custom_fields.delete(:patient)
      self.indexed_fields.delete(:patient)
    end
  end

  def current_patient
    if self.sample.present? && self.sample.patient.present?
      self.sample.patient
    else
      self.patient
    end
  end

  def current_patient=(patient)
    if self.sample.present?
      self.sample.patient = patient
      # TODO AR see if we can remove this by autosaving relation
      self.sample.save!
    else
      self.patient = patient
    end
  end

  def plain_sensitive_data
    @plain_sensitive_data ||= (Oj.load(EventEncryption.decrypt(self.sensitive_data)) || {}).with_indifferent_access
  end

  def pii_data
    # TODO AR include patient here?
    pii = self.plain_sensitive_data
    pii = pii.deep_merge(event.sample.plain_sensitive_data) if self.sample.present?
    pii
  end

  def custom_fields_data
    # TODO AR include patient here?
    data = self.custom_fields
    data = data.deep_merge(self.sample.custom_fields) if self.sample.present?
    data
  end

  def encrypt
    self.sensitive_data = EventEncryption.encrypt Oj.dump(self.plain_sensitive_data)
    self
  end

  def generate_uuid
    self.uuid ||= Guid.new.to_s
  end

  def self.query params, user
    EventQuery.new params, user
  end
end

