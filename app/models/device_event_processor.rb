class DeviceEventProcessor

  def initialize device_event
    @device_event = device_event
  end

  def process
    sample = create_sample
    update_existing_documents_with sample
    create_event sample
  end

  def update_existing_documents_with sample
    response = client.search index: index_name, body:{query: { filtered: { filter: { term: { sample_uuid: sample.uuid } } } }, fields: []}, size: 10000

    body = response["hits"]["hits"].map do |element|
      { update: { _type: element["_type"], _id: element["_id"], data: { doc: sample.indexed_fields } } }
    end

    client.bulk index: index_name, body: body unless body.blank?
  end

  def create_sample
    merged_pii = parsed_event[:sample][:pii].merge parsed_event[:patient][:pii]
    merged_custom_fields = parsed_event[:sample][:custom].merge parsed_event[:patient][:custom]
    merged_indexed_fields = parsed_event[:sample][:indexed].deep_merge parsed_event[:patient][:indexed]

    sample = Sample.new plain_sensitive_data: merged_pii, custom_fields: merged_custom_fields, indexed_fields: merged_indexed_fields, institution_id: @device_event.institution.id

    id = sample.ensure_sample_uid
    if id && existing = Sample.find_by(institution_id: @device_event.institution.id, sample_uid_hash: id)
      existing.merge(sample).save! && existing
    else
      sample.save! && sample
    end
  end

  def create_event sample
    event = Event.new device_events: [@device_event],
                      sample: sample,
                      plain_sensitive_data: parsed_event[:event][:pii],
                      custom_fields: parsed_event[:event][:custom],
                      event_id: parsed_event[:event][:indexed][:event_id],
                      device: device

    if event.event_id && existing = Event.find_by(event_id: event.event_id, device_id: event.device_id)
      existing.merge(event).save!
      EventIndexer.new(parsed_event[:event][:indexed], existing).update
      existing
    else
      event.save!
      EventIndexer.new(parsed_event[:event][:indexed], event).index
      event
    end
  end

  def index_name
    @device_event.institution.elasticsearch_index_name
  end

  def client
    Cdx::Api.client
  end

  def parsed_event
    @device_event.parsed_event
  end

  def device
    @device_event.device
  end
end
