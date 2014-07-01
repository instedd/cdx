class Event < ActiveRecord::Base
  belongs_to :device
  belongs_to :institution
  serialize :custom_fields

  before_create :generate_uuid
  before_create :extract_event_id
  before_save :extract_pii
  before_save :extract_custom_fields
  before_save :encrypt
  after_save :save_in_elasticsearch

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
      {
        name: :created_at,
        type: :date,
        queryable_options: [
          {"since" => {range: [from: {include_lower: true}]}},
          {"until" => {range: [to: {include_lower: true}]}}
        ]
      },
      {
        name: :event_id,
        type: :integer,
        queryable_options: [{"event_id" => :match}]
      },
      {
        name: :device_uuid,
        type: :string,
        queryable_options: [{"device" => :match}]
        },
      {
        name: :laboratory_id,
        type: :integer,
        queryable_options: [{"laboratory" => :match}]
        },
      {
        name: :institution_id,
        type: :integer,
        queryable_options: [{"institution" => :match}]
      },
      {
        name: :location_id,
        type: :integer,
        queryable_options: []
      },
      {
        name: :parent_locations,
        type: :integer,
        queryable_options: [{"location" => :match}]
        },
      {
        name: :age,
        type: :integer,
        queryable_options: [
          {"age" => :match},
          {"min_age" => {range: [from: {include_lower: true}]}},
          {"max_age" => {range: [to: {include_upper: true}]}}
        ]
      },
      {
        name: :assay_name,
        type: :string,
        queryable_options: [{"assay_name" => :wildcard}]
      },
      {
        name: :device_serial_number,
        type: :string,
        queryable_options: []
      },
      {
        name: :gender,
        type: :string,
        queryable_options: [{"gender" => :wildcard}]
      },
      {
        name: :uuid,
        type: :string,
        queryable_options: [{"uuid" => :match}]
      },
      {
        name: :start_time,
        type: :date,
        queryable_options: []
      },
      {
        name: :system_user,
        type: :string,
        queryable_options: []
      },
      {
        name: :results,
        type: :nested,
        sub_fields: [
          {
            name: :result,
            type: :multi_field,
            queryable_options: [{"result" => :wildcard}]
          },
          {
            name: :condition,
            type: :string,
            queryable_options: [{"condition" => :wildcard}]
          }
        ]
      }
    ]
  end

  def decrypt
    self.raw_data = Encryptor.decrypt self.raw_data, :key => secret_key, :iv => iv, :salt => salt
    self.sensitive_data = Oj.load(Encryptor.decrypt(self.sensitive_data, :key => secret_key, :iv => iv, :salt => salt)).with_indifferent_access
    self
  end

  def encrypt
    self.raw_data = Encryptor.encrypt self.raw_data, :key => secret_key, :iv => iv, :salt => salt
    self.sensitive_data = Encryptor.encrypt Oj.dump(self.sensitive_data), :key => secret_key, :iv => iv, :salt => salt
    self
  end

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

  def parsed_fields
    @parsed_fields ||= (device.manifests.order("version DESC").first || Manifest.default).apply_to(Oj.load raw_data).with_indifferent_access
  end

  private

  def indexed_fields
    if device.laboratories.size == 1
      laboratory = device.laboratories.first
      laboratory_id = laboratory.id
      location = device.locations.first
      location_id = location.id
      parent_locations = location.self_and_ancestors.map &:id
    elsif device.laboratories.size == 0
      laboratory_id = nil
      location_id = nil
      parent_locations = []
    else
      laboratory_id = nil
      locations = device.locations
      location = locations.first
      location = location.common_root_with(locations[1..-1])
      location_id = location.id
      parent_locations = location.self_and_ancestors.map &:id
    end

    parsed_fields[:indexed].merge(
      created_at: self.created_at.utc.iso8601,
      updated_at: self.updated_at.utc.iso8601,
      device_uuid: device.secret_key,
      uuid: uuid,
      location_id: location_id,
      parent_locations: parent_locations,
      laboratory_id: laboratory_id
    )
  end

  def generate_uuid
    self.uuid = Guid.new.to_s
  end

  def extract_event_id
    self.event_id = indexed_fields[:event_id] || self.uuid
  end

  def save_in_elasticsearch
    client = Elasticsearch::Client.new log: true
    client.index index: device.institution.elasticsearch_index_name, type: 'result', body: indexed_fields, id: "#{device.secret_key}_#{self.event_id}"
  end

  def extract_pii
    self.sensitive_data = parsed_fields[:pii]
  end

  def extract_custom_fields
    self.custom_fields = parsed_fields[:custom].with_indifferent_access
  end

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
