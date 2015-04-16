class EventIndexer
  attr_reader :event, :fields

  def initialize fields, event
    @fields = fields
    @event = event
  end

  def device
    event.device
  end

  def index
    client.index index: index_name, type: type, body: indexed_fields, id: elasticsearch_id
  end

  def update
    client.update index: index_name, type: type, body: {doc: indexed_fields}, id: elasticsearch_id
  end

  def type
    if device.current_manifest.present?
      "event_#{device.current_manifest.id}"
    else
      'event'
    end
  end

  def elasticsearch_id
    "#{device.uuid}_#{event.event_id || event.uuid}"
  end

  def index_name
    device.institution.elasticsearch_index_name
  end

  def client
    Cdx::Api.client
  end

  def indexed_fields
    if device.laboratories.size == 1
      laboratory = device.laboratories.first
      laboratory_id = laboratory.id
      location = device.locations(ancestors: true).first
    elsif device.laboratories.size == 0
      laboratory_id = nil
      location_id = nil
      location = nil
    else
      laboratory_id = nil
      locations = device.locations(ancestors: true)
      location = Location.common_root(locations)
    end

    unless fields[:start_time].present?
      fields[:start_time] = event.created_at.utc.iso8601
    end

    location_id = location.try(:geo_id)
    parent_locations = location.try(:self_and_ancestors) || []
    parent_locations_id = parent_locations.map &:geo_id
    admin_levels = Hash[parent_locations.map { |l| ["admin_level_#{l.admin_level}", l.geo_id] }]

    properties = {
      created_at: event.created_at.utc.iso8601,
      updated_at: event.updated_at.utc.iso8601,
      device_uuid: device.uuid,
      uuid: event.uuid,
      location_id: location_id,
      parent_locations: parent_locations_id,
      laboratory_id: laboratory_id,
      institution_id: device.institution_id,
      location: admin_levels,
      event_id: event.event_id,
      sample_uuid: event.sample.uuid
    }

    fields.
      merge(properties).
      deep_merge(event.sample.indexed_fields || {})
  end
end
