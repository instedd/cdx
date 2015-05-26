class Event < ActiveRecord::Base
  has_and_belongs_to_many :device_events
  belongs_to :device
  has_one :institution, through: :device
  belongs_to :sample
  belongs_to :patient
  serialize :custom_fields
  validates_presence_of :device
  validates_uniqueness_of :event_id, scope: :device_id, allow_nil: true

  before_create :generate_uuid
  before_save :encrypt

  after_initialize do
    self.custom_fields  ||= {}
  end

  attr_writer :plain_sensitive_data

  delegate :device_model, :device_model_id, to: :device

  def merge(event)
    self.plain_sensitive_data.deep_merge_not_nil!(event.plain_sensitive_data)
    self.custom_fields.deep_merge_not_nil!(event.custom_fields)
    self.sample_id = event.sample_id unless event.sample_id.blank?
    self.device_events |= event.device_events
    self
  end

  def plain_sensitive_data
    @plain_sensitive_data ||= (Oj.load(EventEncryption.decrypt(self.sensitive_data)) || {}).with_indifferent_access
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

