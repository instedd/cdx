class TestResultIndexer
  attr_reader :test_result, :fields

  def initialize test_result
    @test_result = test_result
  end

  def device
    test_result.device
  end

  def index(refresh = false)
    fields = core_fields()
    run_before_index_hooks(fields)
    options = {index: Cdx::Api.index_name, type: type, body: fields, id: elasticsearch_id}
    options[:refresh] = true if refresh
    client.index(options)

    percolate_result = client.percolate index: Cdx::Api.index_name,
                                        type: type,
                                        id: CGI.escape(elasticsearch_id)
    percolate_result["matches"].each do |match|
      subscriber_id = match["_id"]
      NotifySubscriberJob.perform_later subscriber_id, test_result.uuid
    end
  end

  def run_before_index_hooks(fields)
    Cdx.core_field_scopes.each do |scope|
      scope.fields.each do |field|
        field.before_index fields
      end
    end
  end

  def type
    'test'
  end

  def elasticsearch_id
    "#{device.uuid}_#{test_result.test_id || test_result.uuid}"
  end

  def client
    Cdx::Api.client
  end

  def core_fields
    laboratory = device.laboratory
    laboratory_uuid = laboratory.try &:uuid
    laboratory_name = laboratory.try &:name

    location = laboratory.try &:location
    location_id = location.try(:geo_id)
    location_lat = location.try(:lat)
    location_lng = location.try(:lng)

    parent_locations = location.try(:self_and_ancestors) || []
    parent_locations_id = parent_locations.map(&:geo_id)
    admin_levels = Hash[parent_locations.map { |l| ["admin_level_#{l.admin_level}", l.geo_id] }]

    {test_result.entity_scope => test_result.core_fields}.
      deep_merge({
        "test" => {
          "reported_time" => test_result.created_at.utc.iso8601,
          "updated_time" => test_result.updated_at.utc.iso8601,
          "uuid" => test_result.uuid
        },
        "device" => {
          "uuid" => device.uuid,
          "model" => device.device_model.name,
          "serial_number" => device.serial_number
        },
        "location" => {
          "id" => location_id,
          "parents" => parent_locations_id,
          "admin_levels" => admin_levels,
          "lat" => location_lat,
          "lng" => location_lng
        },
        "institution" => {
          "uuid" => device.institution.uuid
        },
        "laboratory" => {
          "uuid" => laboratory_uuid
        }
      }).
      deep_merge(core_fields_from(test_result.sample)).
      deep_merge(core_fields_from(test_result.encounter)).
      deep_merge(core_fields_from(test_result.patient)).
      deep_merge(all_custom_fields)
  end

  def core_fields_from entity
    if entity && !entity.empty_entity?
      {entity.entity_scope => entity.core_fields.deep_merge("uuid" => entity.uuid)}
    else
      {}
    end
  end

  def all_custom_fields
    fields = {}

    append_custom_fields fields, test_result

    if test_result.sample.present?
      append_custom_fields fields, test_result.sample
    end

    if test_result.encounter.present?
      append_custom_fields fields, test_result.encounter
    end

    if test_result.patient.present?
      append_custom_fields fields, test_result.patient
    end

    fields
  end

  def append_custom_fields fields, entity
    if entity.custom_fields.present?
      fields[entity.entity_scope] ||= { "custom_fields" => {} }
      fields[entity.entity_scope]["custom_fields"].deep_merge! entity.custom_fields
    end
  end
end
