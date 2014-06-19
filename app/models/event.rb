class Event < ActiveRecord::Base
  belongs_to :device
  belongs_to :institution

  before_create :generate_uuid
  before_save :encrypt
  after_create :create_in_elasticsearch
  after_update :update_in_elasticsearch

  def self.pii?(field)
    sensitive_fields.include? field.to_sym
  end

  def self.sensitive_fields
    [
      :patient_id,
      :patient_name,
      :patient_telephone_number,
      :patient_zip_code,
    ]
  end

  def self.searchable_fields
    [
      [:created_at, :date, [
        {"since" => {range: [from: {include_lower: true}]}},
        {"until" => {range: [to: {include_lower: true}]}}
      ]],
      [:event_id, :integer, {"event_id" => :match}],
      [:device_uuid, :string, {"device" => :match}],
      [:laboratory_id, :integer, {"laboratory" => :match}],
      [:institution_id, :integer, {"institution" => :match}],
      [:location_id, :integer, []],
      [:parent_locations, :integer, {"location" => :match}],
      [:age, :integer, [
        {"age" => :match},
        {"min_age" => {range: [from: {include_lower: true}]}},
        {"max_age" => {range: [to: {include_upper: true}]}},
      ]],
      [:assay_name, :string, {"assay_name" => :wildcard}],
      [:device_serial_number, :string, []],
      [:gender, :string, {"gender" => :wildcard}],
      [:uuid, :string, {"uuid" => :match}],
      [:start_time, :date, []],
      [:system_user, :string, []],
      [:results, :nested, [
        [:result, :multi_field, {"result" => :wildcard}],
        [:condition, :string, {"condition" => :wildcard}],
      ]],
    ]
  end

  def decrypt
    self.raw_data = Encryptor.decrypt(self.raw_data, :key => secret_key, :iv => iv, :salt => salt)
    self
  end

  def encrypt
    self.raw_data = Encryptor.encrypt(self.raw_data, :key => secret_key, :iv => iv, :salt => salt)
    self
  end

  def generate_uuid

  end

  def create_in_elasticsearch
    client = Elasticsearch::Client.new log: true
    client.index index: device.institution.elasticsearch_index_name, type: 'result', body: Oj.load(Encryptor.decrypt(self.raw_data, :key => secret_key, :iv => iv, :salt => salt)).merge( created_at: self.created_at, updated_at: self.updated_at, device_uuid: device.secret_key)
  end

  def update_in_elasticsearch

  end

  private

  def secret_key
    'a very secret key'
  end

  def iv
    # OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_iv
    "\xD7\xCA\xD5\x9D\x1D\xC0I\x01Sf\xC8\xFBa\x88\xE1\x03"
  end

  def salt
    # Time.now.to_i.to_s
    "1403203711"
  end
end
