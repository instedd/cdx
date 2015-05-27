# Given a device event, creates the associated events in the DB with their samples, and indexes them
class DeviceEventProcessor

  attr_reader :device_event

  def initialize device_event
    @device_event = device_event
  end

  def process
    @device_event.parsed_events.map do |parsed_event|
      SingleEventProcessor.new(self, parsed_event).process
    end
  end

  def client
    @client ||= Cdx::Api.client
  end

  def index_name
    @device_event.institution.elasticsearch_index_name
  end

  def device
    @device_event.device
  end

  def institution
    @device_event.institution
  end


  class SingleEventProcessor

    attr_reader :parsed_event, :parent

    delegate :index_name, :device, :device_event, :client, to: :parent

    def initialize(device_event_processor, parsed_event)
      @parent = device_event_processor
      @parsed_event = parsed_event
    end

    def process
      event = find_or_initialize_event
      process_sample event
      process_patient event

      is_new = event.new_record?
      event.save!

      index_event event, is_new
    end

    private

    # def create_sample(patient)
    #   pii = parsed_event[:sample][:pii].with_indifferent_access
    #   custom_fields = parsed_event[:sample][:custom].with_indifferent_access
    #   indexed_fields = parsed_event[:sample][:indexed].with_indifferent_access

    #   sample = Sample.new plain_sensitive_data: pii, custom_fields: custom_fields, indexed_fields: indexed_fields, institution_id: @parent.institution.id, patient_id: patient.id

    #   id = sample.ensure_sample_uid
    #   if id and existing = Sample.find_by(institution_id: @parent.institution.id, sample_uid_hash: id)
    #     existing_indexed = existing.indexed_fields.deep_dup
    #     existing.merge(sample).save!
    #     update_existing_documents_with(existing) if existing.indexed_fields != existing_indexed
    #     existing
    #   else
    #     sample.save!
    #     sample
    #   end
    # end

    # def update_existing_documents_with sample
    #   response = client.search index: index_name, body:{query: { filtered: { filter: { term: { sample_uuid: sample.uuid } } } }, fields: []}, size: 10000
    #   body = response["hits"]["hits"].map do |element|
    #     { update: { _type: element["_type"], _id: element["_id"], data: { doc: sample.indexed_fields } } }
    #   end

    #   client.bulk index: index_name, body: body unless body.blank?
    # end

    def find_or_initialize_event
      event = Event.new device_events: [device_event],
                        plain_sensitive_data: parsed_event[:event][:pii],
                        custom_fields: parsed_event[:event][:custom],
                        event_id: parsed_event[:event][:indexed][:event_id],
                        device: device

      if event.event_id && existing = Event.find_by(event_id: event.event_id, device_id: event.device_id)
        existing.merge(event)
        existing
      else
        event
      end
    end

    def find_or_initialize_sample
      pii = parsed_event[:sample][:pii].with_indifferent_access
      custom_fields = parsed_event[:sample][:custom].with_indifferent_access
      indexed_fields = parsed_event[:sample][:indexed].with_indifferent_access
      sample_uid = pii[:sample_uid]

      sample = Sample.new plain_sensitive_data: pii,
                          custom_fields: custom_fields,
                          indexed_fields: indexed_fields,
                          institution_id: @parent.institution.id

      if sample_uid.present? && existing = Sample.find_by_pii(sample_uid, @parent.institution.id)
        existing.merge(sample)
        existing
      else
        sample
      end
    end

    def find_or_initialize_patient
      pii = parsed_event[:patient][:pii].with_indifferent_access
      custom_fields = parsed_event[:patient][:custom].with_indifferent_access
      indexed_fields = parsed_event[:patient][:indexed].with_indifferent_access
      patient_id = pii[:patient_id]

      patient = Patient.new plain_sensitive_data: pii,
                            custom_fields: custom_fields,
                            indexed_fields: indexed_fields,
                            institution_id: @parent.institution.id
      if patient_id.present? && existing = Patient.find_by_pii(patient_id, @parent.institution.id)
        existing.merge(patient)
        existing
      else
        patient
      end
    end

    def process_sample(event)
      sample = find_or_initialize_sample

      if event.sample.present?
        if sample.sample_uid.present?
          if event.sample.sample_uid == sample.sample_uid
            event.sample.merge sample
            event.sample.save!
          else
            sample.save!
            event.sample = sample
            # TODO try to delete old sample
          end
        else
          event.sample.merge sample
          event.sample.save!
        end
      else
        if sample.sample_uid.present?
          event.extract_sample_data_into sample
          sample.save!
          event.sample = sample
        else
          event.add_sample_data sample
        end
      end
    end

    def process_patient(event)
      patient = find_or_initialize_patient
      current = event.current_patient

      if current.present?
        if patient.patient_id.present?
          if current.patient_id == patient.patient_id
            current.merge patient
            current.save!
          else
            patient.save!
            event.current_patient = patient
            # TODO try to delete old patient
          end
        else
          current.merge patient
          current.save!
        end
      else
        if patient.patient_id.present?
          event.extract_patient_data_into patient
          patient.save!
          event.current_patient = patient
        else
          event.add_patient_data patient
        end
      end
    end

    def index_event(event, is_new)
      indexer = EventIndexer.new(parsed_event[:event][:indexed], event)
      is_new ? indexer.index : indexer.update
    end

    # def create_event sample
    #   event = Event.new device_events: [device_event],
    #                     sample: sample,
    #                     plain_sensitive_data: parsed_event[:event][:pii],
    #                     custom_fields: parsed_event[:event][:custom],
    #                     event_id: parsed_event[:event][:indexed][:event_id],
    #                     device: device

    #   if event.event_id && existing = Event.find_by(event_id: event.event_id, device_id: event.device_id)
    #     existing.merge(event).save!
    #     EventIndexer.new(parsed_event[:event][:indexed], existing).update
    #     existing
    #   else
    #     event.save!
    #     EventIndexer.new(parsed_event[:event][:indexed], event).index
    #     event
    #   end
    # end

  end

end
