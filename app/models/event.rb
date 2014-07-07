class Event < ActiveRecord::Base
  include EventFieldDefinition
  include EventIndexing
  include EventEncryption
  include EventFiltering
  belongs_to :device
  belongs_to :institution
  serialize :custom_fields

  before_create :generate_uuid
  before_create :extract_event_id
  before_save :extract_pii
  before_save :extract_custom_fields
  before_save :encrypt
  after_save :save_in_elasticsearch

  def self.create_or_update_with device, raw_data
    event = self.new device: device, raw_data: raw_data
    if event.parsed_fields[:indexed][:event_id] && existing_event = self.find_by(device: device, event_id: event.parsed_fields[:indexed][:event_id])
      existing_event.update_with raw_data
    else
      event.save
    end
  end

  def update_with raw_data
    self.raw_data = raw_data
    @parsed_fields = nil
    save
  end
end
