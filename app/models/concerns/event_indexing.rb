module EventIndexing
  extend ActiveSupport::Concern

  included do
    def save_in_elasticsearch
      client = Elasticsearch::Client.new log: false
      client.index index: device.institution.elasticsearch_index_name, type: 'event', body: indexed_fields.merge(event_id: self.event_id), id: "#{device.secret_key}_#{self.event_id}"
    end

    def self.pii?(field)
      sensitive_fields.include? field
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
        laboratory_id: laboratory_id,
        institution_id: device.institution_id
      )
    end

    def generate_uuid
      self.uuid = Guid.new.to_s
    end

    def extract_event_id
      self.event_id = indexed_fields[:event_id] || self.uuid
    end

    def extract_pii
      self.sensitive_data = parsed_fields[:pii]
    end

    def extract_custom_fields
      self.custom_fields = parsed_fields[:custom].with_indifferent_access
    end
  end
end
