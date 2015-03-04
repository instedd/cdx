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
    merged_pii = event[:sample][:pii].merge event[:patient][:pii]
    merged_custom_fields = event[:sample][:custom].merge event[:patient][:custom]

    # sample_id = event.parsed_fields[:sample_id]
    # if sample_id && existing_sample = Sample.find_by(institution_id: event.institution.id, sample_id: sample_id)
    #   event.sample = existing_sample
    # else
    #   event.sample = Sample.new sample_id: sample_id, institution_id: event.institution.id
    # end

    Sample.create plain_sensitive_data: merged_pii, custom_fields: merged_custom_fields
  end

  def create_event sample
    Event.create device_events: [@device_event], sample: sample, sensitive_data: event[:event][:pii], custom_fields: event[:event][:custom]
  end

  def index_document event
    event.uuid
    event.sample.uuid

    #TODO index
  end

  def event
    @device_event.parsed_event
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

  # def save_in_elasticsearch
  #   type = if manifest.present?
  #     "event_#{manifest.id}"
  #   else
  #     'event'
  #   end

  #   Cdx::Api.client.index index: device.institution.elasticsearch_index_name, type: type, body: indexed_body, id: "#{device.secret_key}_#{self.event_id}"
  # end

  # def self.pii?(field)
  #   Event.sensitive_fields.include? field
  # end

  # def indexed_body
  #   @indexed_body ||= indexed_fields.merge(event_id: self.event_id)
  # end

  # private

  # def indexed_fields
  #   if device.laboratories.size == 1
  #     laboratory = device.laboratories.first
  #     laboratory_id = laboratory.id
  #     location = device.locations.first
  #     location_id = location.geo_id
  #     parent_locations = location.self_and_ancestors.load
  #   elsif device.laboratories.size == 0
  #     laboratory_id = nil
  #     location_id = nil
  #     parent_locations = []
  #   else
  #     laboratory_id = nil
  #     locations = device.locations
  #     location = locations.first
  #     location = location.common_root_with(locations[1..-1])
  #     location_id = location.geo_id
  #     parent_locations = location.self_and_ancestors.load
  #   end

  #   unless parsed_fields[:indexed][:start_time].present?
  #     parsed_fields[:indexed][:start_time] = self.created_at.utc.iso8601
  #   end

  #   parent_locations_id = parent_locations.map &:geo_id
  #   admin_levels = Hash[parent_locations.map { |l| ["admin_level_#{l.admin_level}", l.geo_id] }]

  #   properties = {
  #     created_at: self.created_at.utc.iso8601,
  #     updated_at: self.updated_at.utc.iso8601,
  #     device_uuid: device.secret_key,
  #     uuid: uuid,
  #     location_id: location_id,
  #     parent_locations: parent_locations_id,
  #     laboratory_id: laboratory_id,
  #     institution_id: device.institution_id,
  #     location: admin_levels,
  #   }

  #   parsed_fields[:indexed].merge(properties)
  # end

  # def extract_event_id
  #   self.event_id = indexed_fields[:event_id] || self.uuid
  # end

  # def extract_custom_fields
  #   self.custom_fields = parsed_fields[:custom].with_indifferent_access
  # end
end
