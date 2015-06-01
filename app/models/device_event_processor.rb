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
      test = find_or_initialize_test
      is_new_test = test.new_record?
      old_sample = test.sample
      old_patient = test.current_patient

      process_sample test
      process_patient test

      sample_changed = test.sample_id_changed?
      patient_changed = test.patient_id_changed? ||
        (test.sample.present? && test.sample.patient_id_changed?)

      test.save!

      if sample_changed && old_sample.present?
        old_sample.destroy
      end

      if patient_changed && old_patient.present?
        old_patient.destroy
      end

      index_test test, is_new_test
    end

    private

    def find_or_initialize_test
      test = TestResult.new device_events: [device_event],
                            plain_sensitive_data: parsed_event[:event][:pii],
                            custom_fields: parsed_event[:event][:custom],
                            test_id: parsed_event[:event][:indexed][:event_id],
                            device: device

      if test.test_id && existing = TestResult.find_by(test_id: test.test_id, device_id: test.device_id)
        existing.merge(test)
        existing
      else
        test
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
        existing_indexed = existing.indexed_fields.deep_dup
        existing.merge(sample)
        [existing, existing_indexed]
      else
        [sample, nil]
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
        existing_indexed = existing.indexed_fields.deep_dup
        existing.merge(patient)
        [existing, existing_indexed]
      else
        [patient, nil]
      end
    end

    def process_sample(test)
      sample, existing_indexed = find_or_initialize_sample

      if test.sample.present?
        if sample.sample_uid.present?
          if test.sample.sample_uid == sample.sample_uid
            test.sample.merge sample
          else
            test.sample = sample
          end
        else
          test.sample.merge sample
        end
      else
        if sample.sample_uid.present?
          test.extract_sample_data_into sample
          test.sample = sample
        else
          test.add_sample_data sample
        end
      end

      test.sample.save! if test.sample.present?

      if !existing_indexed.nil? && existing_indexed != test.sample.try(:indexed_fields)
        update_sample_in_existing_documents_with test.sample
      end
    end

    def process_patient(test)
      patient, existing_indexed = find_or_initialize_patient
      current = test.current_patient

      if current.present?
        if patient.patient_id.present?
          if current.patient_id == patient.patient_id
            current.merge patient
          else
            test.current_patient = patient
          end
        else
          current.merge patient
        end
      else
        if patient.patient_id.present?
          test.extract_patient_data_into patient
          test.current_patient = patient
        else
          test.add_patient_data patient
        end
      end

      test.current_patient.save! if test.current_patient.present?

      if !existing_indexed.nil? && existing_indexed != test.current_patient.try(:indexed_fields)
        update_patient_in_existing_documents_with test.current_patient
      end
    end

    def index_test(test, is_new)
      indexer = TestResultIndexer.new(parsed_event[:event][:indexed], test)
      is_new ? indexer.index : indexer.update
    end

    def update_sample_in_existing_documents_with sample
      response = client.search index: index_name, body:{query: { filtered: { filter: { term: { sample_uuid: sample.uuid } } } }, fields: []}, size: 10000
      body = response["hits"]["hits"].map do |element|
        { update: { _type: element["_type"], _id: element["_id"], data: { doc: sample.indexed_fields } } }
      end

      client.bulk index: index_name, body: body unless body.blank?
    end

    def update_patient_in_existing_documents_with patient
      response = client.search index: index_name, body:{query: { filtered: { filter: { term: { patient_uuid: patient.uuid } } } }, fields: []}, size: 10000
      body = response["hits"]["hits"].map do |element|
        { update: { _type: element["_type"], _id: element["_id"], data: { doc: patient.indexed_fields } } }
      end

      client.bulk index: index_name, body: body unless body.blank?
    end

  end

end
