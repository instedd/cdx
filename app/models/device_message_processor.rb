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
      old_sample = test.sample
      old_patient = test.patient
      old_encounter = test.encounter

      new_sample,    sample_core_fields    = find_or_initialize_sample
      new_encounter, encounter_core_fields = find_or_initialize_encounter
      new_patient,   patient_core_fields   = find_or_initialize_patient

      connect_before test, new_sample, new_encounter, new_patient

      process_sample    test, new_sample      if new_sample
      process_encounter test, new_encounter   if new_encounter
      process_patient   test, new_patient     if new_patient

      connect_after test

      save_entity test.sample,    sample_core_fields
      save_entity test.encounter, encounter_core_fields
      save_entity test.patient,   patient_core_fields

      test.save!

      index_test test
    end

    private

    def find_or_initialize_test
      test_id = parsed_message["test"]["core"]["id"]
      test = TestResult.new device_messages: [device_message],
                            test_id: test_id,
                            device: device
      assign_fields parsed_message, test

      if test_id && existing = TestResult.from_the_past_year(@parent.device_message.created_at).find_by(test_id: test_id, device_id: test.device_id)
        existing.merge(test)
        existing
      else
        test
      end
    end

    def find_or_initialize_sample
      find_or_initialize_entity Sample, ((parsed_message["sample"] || {})["core"] || {})["id"]
    end

    def find_or_initialize_patient
      find_or_initialize_entity Patient, ((parsed_message["patient"] || {})["pii"] || {})["id"]
    end

    def find_or_initialize_encounter
      find_or_initialize_entity Encounter, ((parsed_message["encounter"] || {})["core"] || {})["id"]
    end

    def find_or_initialize_entity(klass, entity_id, scope_by_last_year = true)
      new_entity = klass.new institution_id: @parent.institution.id
      assign_fields parsed_message, new_entity

      if entity_id && (existing = find_entity_by_id(klass, entity_id, scope_by_last_year))
        existing_indexed = existing.core_fields.deep_dup
        existing.merge(new_entity)
        [existing, existing_indexed]
      elsif new_entity.empty_entity?
        [nil, nil]
      else
        [new_entity, nil]
      end
    end

    def find_entity_by_id(klass, entity_id, scope_by_last_year = true)
      query = klass
      if scope_by_last_year
        query = query.from_the_past_year(@parent.device_message.created_at)
      end
      query.find_by_entity_id(entity_id, @parent.institution.id)
    end

    def process_sample(test, sample)
      unless test.sample
        test.sample = sample
        return
      end

      if !sample.entity_id || same_uid?(sample, test.sample)
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

      if !encounter.entity_id || same_uid?(encounter, test.encounter)
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

      # Here we don't take the year into account
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

    def same_uid?(new_entity, existing_entity)
      return false unless new_entity.entity_id == existing_entity.entity_id

      new_entity_created_at = new_entity.created_at || @parent.device_message.created_at
      (new_entity_created_at - existing_entity.created_at).abs < 1.year
    end

    def index_test(test)
      indexer = TestResultIndexer.new(test)
      indexer.index
    end

    def assign_fields(parsed_message, entity)
      entity.core_fields          = (parsed_message[entity.entity_scope] || {})["core"] || {}
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

    def save_entity(entity, old_core_fields)
      entity.try :save!

      return unless old_core_fields && old_core_fields != entity.try(:core_fields)

      response = client.search index: Cdx::Api.index_name, body:{query: { filtered: { filter: { term: { "#{entity.entity_scope}.uuid" => entity.uuid } } } }, fields: []}, size: 10000
      body = response["hits"]["hits"].map do |element|
        { update: { _type: element["_type"], _id: element["_id"], data: { doc: {entity.entity_scope => entity.core_fields} } } }
      end

      client.bulk index: Cdx::Api.index_name, body: body unless body.blank?
    end
  end
end
