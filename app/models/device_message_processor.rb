# Given a device message, creates the associated messages in the DB with their samples, and indexes them
class DeviceMessageProcessor
  attr_reader :device_message

  def initialize device_message
    @device_message = device_message
  end

  def process
    @device_message.parsed_messages.map do |parsed_message|
      SingleMessageProcessor.new(self, parsed_message).process
    end
  end

  def client
    @client ||= Cdx::Api.client
  end

  def device
    @device_message.device
  end

  def institution
    @device_message.institution
  end

  class SingleMessageProcessor
    attr_reader :parsed_message, :parent

    delegate :device, :device_message, :client, to: :parent

    def initialize(device_message_processor, parsed_message)
      @parent = device_message_processor
      @parsed_message = parsed_message
    end

    def process
      test = find_or_initialize_test
      is_new_test = test.new_record?
      old_sample = test.sample
      old_patient = test.patient
      old_encounter = test.encounter

      new_sample,    sample_indexed_fields    = find_or_initialize_sample
      new_encounter, encounter_indexed_fields = find_or_initialize_encounter
      new_patient,   patient_indexed_fields   = find_or_initialize_patient

      connect_before test, new_sample, new_encounter, new_patient

      process_sample    test, new_sample      if new_sample
      process_encounter test, new_encounter   if new_encounter
      process_patient   test, new_patient     if new_patient

      connect_after test

      save_entity test.sample,    sample_indexed_fields
      save_entity test.encounter, encounter_indexed_fields
      save_entity test.patient,   patient_indexed_fields

      test.save!

      index_test test, is_new_test
    end

    private

    def find_or_initialize_test
      test_id = parsed_message["test"]["indexed"]["id"]
      test = TestResult.new device_messages: [device_message],
                            test_id: test_id,
                            device: device
      assign_fields parsed_message, test

      if test_id && existing = TestResult.find_by(test_id: test_id, device_id: test.device_id)
        existing.merge(test)
        existing
      else
        test
      end
    end

    def find_or_initialize_sample
      find_or_initialize_entity Sample, ((parsed_message["sample"] || {})["pii"] || {})["uid"]
    end

    def find_or_initialize_patient
      find_or_initialize_entity Patient, ((parsed_message["patient"] || {})["pii"] || {})["id"]
    end

    def find_or_initialize_encounter
      find_or_initialize_entity Encounter, ((parsed_message["encounter"] || {})["pii"] || {})["id"]
    end

    def find_or_initialize_entity(klass, entity_id)
      new_entity = klass.new institution_id: @parent.institution.id
      assign_fields parsed_message, new_entity

      if entity_id && (existing = klass.find_by_pii(entity_id, @parent.institution.id))
        existing_indexed = existing.indexed_fields.deep_dup
        existing.merge(new_entity)
        [existing, existing_indexed]
      elsif new_entity.empty_entity?
        [nil, nil]
      else
        [new_entity, nil]
      end
    end

    def process_sample(test, sample)
      unless test.sample
        test.sample = sample
        return
      end

      if !sample.entity_id || (sample.entity_id == test.sample.entity_id)
        test.sample.merge sample
        return
      end

      unless test.sample.entity_id
        sample.merge test.sample
        test.sample.destroy
      end

      test.sample = sample
    end

    def process_encounter(test, encounter)
      unless test.encounter
        test.encounter = encounter
        return
      end

      if !encounter.entity_id || (encounter.entity_id == test.encounter.entity_id)
        test.encounter.merge encounter
        return
      end

      unless test.encounter.entity_id
        encounter.merge test.encounter
        test.encounter.destroy
      end

      test.encounter = encounter
    end

    def process_patient(test, patient)
      unless test.patient
        test.patient = patient
        return
      end

      if !patient.entity_id || (patient.entity_id == test.patient.entity_id)
        test.patient.merge patient
        return
      end

      unless test.patient.entity_id
        patient.merge test.patient
        test.patient.destroy
      end

      test.patient = patient
    end

    def index_test(test, is_new)
      indexer = TestResultIndexer.new(test)
      is_new ? indexer.index : indexer.update
    end

    def assign_fields(parsed_message, entity)
      entity.indexed_fields       = (parsed_message[entity.entity_scope] || {})["indexed"] || {}
      entity.custom_fields        = (parsed_message[entity.entity_scope] || {})["custom"] || {}
      entity.plain_sensitive_data = (parsed_message[entity.entity_scope] || {})["pii"] || {}
    end

    def connect_before(test, sample, encounter, patient)
      unless test.patient
        if encounter && encounter.patient
          test.patient = encounter.patient
        elsif sample && sample.patient
          test.patient = sample.patient
        end
      end

      unless test.encounter
        if sample && sample.encounter
          test.encounter = sample.encounter
        end
      end
    end

    def connect_after(test)
      if test.encounter
        test.encounter.patient = test.patient
      end

      if test.sample
        test.sample.encounter = test.encounter
        test.sample.patient   = test.patient
      end
    end

    def save_entity(entity, old_indexed_fields)
      entity.try :save!

      return unless old_indexed_fields && old_indexed_fields != entity.try(:indexed_fields)

      response = client.search index: Cdx::Api.index_name, body:{query: { filtered: { filter: { term: { "#{entity.entity_scope}.uuid" => entity.uuid } } } }, fields: []}, size: 10000
      body = response["hits"]["hits"].map do |element|
        { update: { _type: element["_type"], _id: element["_id"], data: { doc: {entity.entity_scope => entity.indexed_fields} } } }
      end

      client.bulk index: Cdx::Api.index_name, body: body unless body.blank?
    end
  end
end
