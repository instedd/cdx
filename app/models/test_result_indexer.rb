class TestResultIndexer
  attr_reader :test_result, :fields

  def initialize fields, test_result
    @fields = fields
    @test_result = test_result
  end

  def device
    test_result.device
  end

  def index
    client.index index: index_name, type: type, body: indexed_fields, id: elasticsearch_id
  end

  def update
    client.update index: index_name, type: type, body: {doc: indexed_fields}, id: elasticsearch_id
  end

  def type
    if device.current_manifest.present?
      "test_#{device.device_model_id}"
    else
      'test'
    end
  end

  def elasticsearch_id
    "#{device.uuid}_#{test_result.test_id || test_result.uuid}"
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
      fields[:start_time] = test_result.created_at.utc.iso8601
    end

    location_id = location.try(:geo_id)
    parent_locations = location.try(:self_and_ancestors) || []
    parent_locations_id = parent_locations.map(&:geo_id)
    admin_levels = Hash[parent_locations.map { |l| ["admin_level_#{l.admin_level}", l.geo_id] }]

    properties = {
      created_at: test_result.created_at.utc.iso8601,
      updated_at: test_result.updated_at.utc.iso8601,
      device_uuid: device.uuid,
      uuid: test_result.uuid,
      location_id: location_id,
      parent_locations: parent_locations_id,
      laboratory_id: laboratory_id,
      institution_id: device.institution_id,
      location: admin_levels,
      test_id: test_result.test_id
    }

    if test_result.sample.present?
      properties[:sample_uuid] = test_result.sample.uuid
    end

    if test_result.current_patient.present?
      properties[:patient_uuid] = test_result.current_patient.uuid
    end

    fields.
      merge(properties).
      deep_merge(test_result.sample.try(:indexed_fields) || {}).
      deep_merge(test_result.current_patient.try(:indexed_fields) || {})
  end
end
