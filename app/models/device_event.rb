class DeviceEvent < ActiveRecord::Base
  belongs_to :device
  has_one :institution, through: :device
  has_and_belongs_to_many :events

  before_save :parsed_event
  before_save :encrypt

  attr_writer :plain_text_data

  def plain_text_data
    @plain_text_data ||= EventEncryption.decrypt self.raw_data
  end

  def parsed_event
    @parsed_event ||= (device.current_manifest || Manifest.default).apply_to(plain_text_data).with_indifferent_access
  rescue ManifestParsingError => err
    self.index_failed = true
    self.index_failure_reason = err.message
  end

  def extract_pii
    self.sample.merge_sensitive_data parsed_fields[:pii]
    self.sample.save!
  end

  def process
    DeviceEventProcessor.new(self).process
  end

  def encrypt
    self.raw_data = EventEncryption.encrypt self.plain_text_data
    self
  end
end
