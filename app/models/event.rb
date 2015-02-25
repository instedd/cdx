class Event < ActiveRecord::Base
  include EventIndexing

  belongs_to :device
  has_one :institution, through: :device
  belongs_to :sample
  serialize :custom_fields

  before_create :generate_uuid
  before_create :extract_event_id, :unless => :index_failed?
  before_save :extract_pii, :unless => :index_failed?
  before_save :extract_custom_fields, :unless => :index_failed?
  before_save :encrypt, :unless => :index_failed?
  after_save :save_in_elasticsearch, :unless => :index_failed?

  def decrypt
    self.raw_data = EventEncryption.decrypt self.raw_data
    self
  end

  def encrypt
    self.raw_data = EventEncryption.encrypt self.raw_data
    self
  end

  def self.create_or_update_with device, raw_data
    event = self.new device: device, raw_data: raw_data

    event_id = event.parsed_fields[:indexed][:event_id]

    if event_id && existing_event = self.find_by(device: device, event_id: event_id)
      result = existing_event.update_with raw_data
      [existing_event, result]
    else
      sample_id = event.parsed_fields[:sample_id]
      if sample_id && existing_sample = Sample.find_by(institution_id: event.institution.id, sample_id: sample_id)
        event.sample = existing_sample
      else
        event.sample = Sample.new sample_id: sample_id, institution_id: event.institution.id
      end
      result = event.save
      [event, result]
    end
  rescue ManifestParsingError => err
    event.index_failed = true
    event.index_failure_reason = err.message
    result = event.save
    [event, result]
  rescue EventParsingError => err
    event.errors.add(:raw_data, err.message)
    [event, false]
  end

  def self.sensitive_fields
    ["patient_id", "patient_name", "patient_telephone_number", "patient_zip_code"]
  end

  def update_with raw_data
    self.raw_data = raw_data
    @parsed_fields = nil
    save
  end

  def self.query params, user
    EventQuery.new params, user
  end
end
