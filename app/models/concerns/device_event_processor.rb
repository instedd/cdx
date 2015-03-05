class DeviceEventProcessor

  def initialize device_event
    @device_event = device_event
  end

  def process
    sample = create_sample
    event = create_event sample
    index_document event
  end

  def create_sample
    merged_pii = parsed_event[:sample][:pii].merge parsed_event[:patient][:pii]
    merged_custom_fields = parsed_event[:sample][:custom].merge parsed_event[:patient][:custom]
    merged_indexed_fields = parsed_event[:sample][:indexed].deep_merge parsed_event[:patient][:indexed]

    # sample_id = event.parsed_fields[:sample_id]
    # if sample_id && existing_sample = Sample.find_by(institution_id: event.institution.id, sample_id: sample_id)
    #   event.sample = existing_sample
    # else
    #   event.sample = Sample.new sample_id: sample_id, institution_id: event.institution.id
    # end

    Sample.create plain_sensitive_data: merged_pii, custom_fields: merged_custom_fields, indexed_fields: merged_indexed_fields
  end

  def create_event sample
    Event.create device_events: [@device_event], sample: sample, plain_sensitive_data: parsed_event[:event][:pii], custom_fields: parsed_event[:event][:custom], event_id: parsed_event[:event][:indexed][:event_id]
  end

  def index_document event
    type = if @device_event.manifest.present?
      "event_#{@device_event.manifest.id}"
    else
      'event'
    end

    client.index index: device.institution.elasticsearch_index_name, type: type, body: indexed_fields(event), id: "#{device.secret_key}_#{event.event_id || event.uuid}"
  end

  def client
    Cdx::Api.client
  end

  def indexed_fields event
    if device.laboratories.size == 1
      laboratory = device.laboratories.first
      laboratory_id = laboratory.id
      location = device.locations.first
      location_id = location.geo_id
      parent_locations = location.self_and_ancestors.load
    elsif device.laboratories.size == 0
      laboratory_id = nil
      location_id = nil
      parent_locations = []
    else
      laboratory_id = nil
      locations = device.locations
      location = locations.first
      location = location.common_root_with(locations[1..-1])
      location_id = location.geo_id
      parent_locations = location.self_and_ancestors.load
    end

    unless parsed_event[:event][:indexed][:start_time].present?
      parsed_event[:event][:indexed][:start_time] = event.created_at.utc.iso8601
    end

    parent_locations_id = parent_locations.map &:geo_id
    admin_levels = Hash[parent_locations.map { |l| ["admin_level_#{l.admin_level}", l.geo_id] }]

    properties = {
      created_at: event.created_at.utc.iso8601,
      updated_at: event.updated_at.utc.iso8601,
      device_uuid: device.secret_key,
      uuid: event.uuid,
      location_id: location_id,
      parent_locations: parent_locations_id,
      laboratory_id: laboratory_id,
      institution_id: device.institution_id,
      location: admin_levels,
      event_id: event.event_id,
      sample_uuid: event.sample.uuid
    }

    parsed_event[:event][:indexed].
      merge(properties).
      deep_merge(event.sample.indexed_fields || {})
  end

  def parsed_event
    @device_event.parsed_event
  end

  def device
    @device_event.device
  end

  # def self.create_or_update_with device_event, parsed_fields
  #   event_id = parsed_fields[:indexed][:event_id]

  #   if event_id && existing_event = self.find_by(device: device, event_id: event_id)
  #     result = existing_event.update_with parsed_fields
  #     [existing_event, result]
  #   else
  #     event = self.new device_event: device_event, parsed_fields: parsed_fields
  #     sample_id = event.parsed_fields[:sample_id]
  #     if sample_id && existing_sample = Sample.find_by(institution_id: event.institution.id, sample_id: sample_id)
  #       event.sample = existing_sample
  #     else
  #       event.sample = Sample.new sample_id: sample_id, institution_id: event.institution.id
  #     end
  #     result = event.save
  #     [event, result]
  #   end
  # end

  # attr_accessor :parsed_fields

  # def self.pii?(field)
  #   Event.sensitive_fields.include? field
  # end

  # def indexed_body
  #   @indexed_body ||= indexed_fields.merge(event_id: self.event_id)
  # end

  # private


  # def extract_event_id
  #   self.event_id = indexed_fields[:event_id] || self.uuid
  # end

  # def extract_custom_fields
  #   self.custom_fields = parsed_fields[:custom].with_indifferent_access
  # end
end
