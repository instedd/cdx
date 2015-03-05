class Event < ActiveRecord::Base
  has_and_belongs_to_many :device_events
  has_one :device, through: :device_evnets
  has_one :institution, through: :device
  belongs_to :sample
  serialize :custom_fields

  before_create :generate_uuid
  before_save :encrypt

  # TODO remove this

  def self.sensitive_fields
    ["patient_id", "patient_name", "patient_telephone_number", "patient_zip_code"]
  end

  attr_writer :plain_sensitive_data

  def plain_sensitive_data
    @plain_sensitive_data ||= (Oj.load(EventEncryption.decrypt(self.sensitive_data)) || {}).with_indifferent_access
  end

  def encrypt
    self.sensitive_data = EventEncryption.encrypt Oj.dump(self.plain_sensitive_data)
    self
  end

  def update_with parsed_data
    # update customs and pii
    save
  end

  def generate_uuid
    self.uuid = Guid.new.to_s
  end

  def self.query params, user
    EventQuery.new params, user
  end
end
