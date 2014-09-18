class Event < ActiveRecord::Base
  include EventIndexing
  include EventEncryption

  belongs_to :device
  belongs_to :institution
  serialize :custom_fields

  before_create :generate_uuid
  before_create :extract_event_id, :unless => :index_failed?
  before_save :extract_pii, :unless => :index_failed?
  before_save :extract_custom_fields, :unless => :index_failed?
  before_save :encrypt, :unless => :index_failed?
  after_save :save_in_elasticsearch, :unless => :index_failed?

  def self.create_or_update_with device, raw_data
    event = self.new device: device, raw_data: raw_data

    event_id = event.parsed_fields[:indexed][:event_id]

    if event_id && existing_event = self.find_by(device: device, event_id: event_id)
      result = existing_event.update_with raw_data
      [existing_event, result]
    else
      result = event.save
      [event, result]
    end
  rescue ManifestParsingError => err
    event.index_failed = true
    event.index_failure_reason = err.message
    result = event.save
    [event, result]
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
