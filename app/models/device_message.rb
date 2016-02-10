class DeviceMessage < ActiveRecord::Base
  belongs_to :device
  belongs_to :site
  has_one :institution, through: :device
  has_and_belongs_to_many :test_results

  validates_presence_of :device

  before_save :parsed_messages
  before_save :encrypt
  before_create :copy_site_from_device

  store :index_failure_data, coder: JSON

  attr_writer :plain_text_data

  def plain_text_data
    @plain_text_data ||= MessageEncryption.decrypt self.raw_data
  end

  def parsed_messages
    @parsed_messages ||= device.current_manifest.apply_to(plain_text_data, device)
  rescue ManifestParsingError => err
    self.record_failure err
    self.index_failure_data[:target_field] = err.target_field if err.target_field.present?
    self.index_failure_data[:number_of_failures] = err.number_of_failures if err.number_of_failures.present?
  rescue => err
    self.record_failure err
  end

  def record_failure err
    self.index_failed = true
    self.index_failure_reason = err.message
  end

  def process
    DeviceMessageProcessor.new(self).process
  rescue => e
    self.record_failure e
    self.save
  end

  def encrypt
    self.raw_data = MessageEncryption.encrypt self.plain_text_data
    self
  end

  def reprocess
    clear_errors
    self.save
    self.process unless self.index_failed
    self
  end

  private

  def clear_errors
    self.index_failed = false
    self.index_failure_reason = nil
    self.index_failure_data = {}
  end

  def copy_site_from_device
    self.site = self.device.site
  end
end
