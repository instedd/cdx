class TestResultIndexer
  attr_reader :test_result, :fields

  def initialize test_result
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
    'test'
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
    location = device.current_location
    location_id = location.try(:geo_id)
    location_lat = location.try(:lat)
    location_lng = location.try(:lng)

    laboratory = device.current_laboratory
    laboratory_id = laboratory.try &:id
    laboratory_name = laboratory.try &:name

    parent_locations = location.try(:self_and_ancestors) || []
    parent_locations_id = parent_locations.map(&:geo_id)
    admin_levels = Hash[parent_locations.map { |l| ["admin_level_#{l.admin_level}", l.geo_id] }]

    test_result.indexed_fields.
      deep_merge({
        test: {
          reported_time: test_result.created_at.utc.iso8601,
          updated_time: test_result.updated_at.utc.iso8601,
          uuid: test_result.uuid
        },
        device: {
          uuid: device.uuid,
          name: device.name
        },
        location: {
          id: location_id,
          parents: parent_locations_id,
          admin_levels: admin_levels,
          lat: location_lat,
          lng: location_lng
        },
        institution: {
          id: device.institution_id,
          name: device.institution.name
        },
        laboratory: {
          id: laboratory_id,
          name: laboratory_name
        }
      }).
      deep_merge(indexed_fields_from(test_result.sample, :sample)).
      deep_merge(indexed_fields_from(test_result.current_patient, :patient)).
      deep_merge(all_custom_fields)
  end

  def indexed_fields_from indexable, scope
    if indexable
      indexable.indexed_fields.deep_merge({scope => {uuid: indexable.uuid }})
    else
      {}
    end
  end

  def all_custom_fields
    fields = {}

    sample = test_result.sample
    patient = test_result.current_patient

    append_custom_fields fields, test_result, :test
    append_custom_fields fields, test_result, :sample
    append_custom_fields fields, test_result, :patient

    if sample.present?
      append_custom_fields fields, sample, :sample
      append_custom_fields fields, sample, :patient
    end

    if patient.present?
      append_custom_fields fields, patient, :patient
    end

    fields
  end

  def append_custom_fields fields, entity, key
    if entity.custom_fields[key].present?
      fields[key] ||= { custom_fields: {} }
      fields[key][:custom_fields].deep_merge! entity.custom_fields[key]
    end
  end

end
