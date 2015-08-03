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

      encounter_indexed_fields = process_encounter test
      sample_indexed_fields    = process_sample    test
      patient_indexed_fields   = process_patient   test

      save_encounter test, encounter_indexed_fields
      save_sample    test, sample_indexed_fields
      save_patient   test, patient_indexed_fields

      encounter_changed = test.encounter_id_changed?
      sample_changed    = test.sample_id_changed?
      patient_changed   = test.patient_id_changed?

      test.save!

      old_encounter.destroy  if encounter_changed && old_encounter
      old_sample.destroy     if sample_changed    && old_sample
      old_patient.destroy    if patient_changed   && old_patient

      index_test test, is_new_test
    end

    private

    def find_or_initialize_test
      test_id = parsed_message["test"]["indexed"]["id"]
      test = TestResult.new device_messages: [device_message],
                            test_id: test_id,
                            device: device
      assign_fields parsed_message, test, "test"

      if test_id && existing = TestResult.find_by(test_id: test_id, device_id: test.device_id)
        existing.merge(test)
        existing
      else
        test
      end
    end

    def find_or_initialize_sample
      find_or_initialize_entity Sample, "sample", ((parsed_message["sample"] || {})["pii"] || {})["uid"]
    end

    def find_or_initialize_patient
      find_or_initialize_entity Patient, "patient", ((parsed_message["patient"] || {})["pii"] || {})["id"]
    end

    def find_or_initialize_encounter
      find_or_initialize_entity Encounter, "encounter", ((parsed_message["encounter"] || {})["pii"] || {})["id"]
    end

    def find_or_initialize_entity(klass, scope, entity_id)
      new_entity = klass.new institution_id: @parent.institution.id
      assign_fields parsed_message, new_entity, scope

      if entity_id && (existing = klass.find_by_pii(entity_id, @parent.institution.id))
        existing_indexed = existing.indexed_fields.deep_dup
        existing.merge(new_entity)
        [existing, existing_indexed]
      else
        [new_entity, nil]
      end
    end

    def process_encounter(test)
      encounter, existing_indexed = find_or_initialize_encounter

      if test.encounter
        if encounter.encounter_id && (encounter.encounter_id != test.encounter.encounter_id)
          test.encounter = encounter
        else
          test.encounter.merge_entity_scope encounter, "encounter"
        end
      else
        if encounter.encounter_id
          test.encounter = encounter
          test.move_entity_scope "encounter", test.encounter
        else
          test.merge_entity_scope encounter, "encounter"
        end
      end

      existing_indexed
    end

    def process_sample(test)
      sample, existing_indexed = find_or_initialize_sample

      if test.sample
        if sample.sample_uid && (sample.sample_uid != test.sample.sample_uid)
          test.sample = sample
        else
          test.sample.merge_entity_scope sample, "sample"
        end
      else
        if sample.sample_uid
          test.sample = sample
          test.move_entity_scope "sample", test.sample
        else
          test.merge_entity_scope sample, "sample"
        end
      end

      existing_indexed
    end

    def process_patient(test)
      patient, existing_indexed = find_or_initialize_patient

      if test.patient
        if patient.patient_id && (patient.patient_id != test.patient.patient_id)
          test.patient = patient
        else
          test.patient.merge_entity_scope patient, "patient"
        end
      else
        if patient.patient_id
          test.patient = patient
          test.move_entity_scope "patient", test.patient
        else
          test.merge_entity_scope patient, "patient"
        end
      end

      # Move patient data to sample if there's one,
      # or move sample's patient to test, if the test has no patient
      if test.sample
        test.move_entity_scope "patient", test.sample

        if test.patient
          test.sample.move_entity_scope "patient", test.patient
          test.sample.patient = test.patient
        else
          test.sample.merge_entity_scope patient, "patient"
          if test.sample.patient
            test.patient = test.sample.patient
            test.sample.patient.merge_entity_scope patient, "patient"
          end
        end
      end

      existing_indexed
    end

    def index_test(test, is_new)
      indexer = TestResultIndexer.new(test)
      is_new ? indexer.index : indexer.update
    end

    def assign_fields(parsed_message, entity, scope)
      entity.indexed_fields       = {scope => (parsed_message[scope] || {})["indexed"]}
      entity.custom_fields        = {scope => (parsed_message[scope] || {})["custom"]}
      entity.plain_sensitive_data = {scope => (parsed_message[scope] || {})["pii"]}
    end

    def update_entity_in_elasticsearch(entity, key)
      response = client.search index: Cdx::Api.index_name, body:{query: { filtered: { filter: { term: { key => entity.uuid } } } }, fields: []}, size: 10000
      body = response["hits"]["hits"].map do |element|
        { update: { _type: element["_type"], _id: element["_id"], data: { doc: entity.indexed_fields } } }
      end

      client.bulk index: Cdx::Api.index_name, body: body unless body.blank?
    end

    def save_encounter(test, old_indexed_fields)
      test.encounter.try(:save!)

      if old_indexed_fields && old_indexed_fields != test.encounter.try(:indexed_fields)
        update_entity_in_elasticsearch test.encounter, 'encounter.uuid'
      end
    end

    def save_sample(test, old_indexed_fields)
      test.sample.try(:save!)

      if old_indexed_fields && old_indexed_fields != test.sample.try(:indexed_fields)
        update_entity_in_elasticsearch test.sample, 'sample.uuid'
      end
    end

    def save_patient(test, old_indexed_fields)
      test.patient.try(:save!)

      if old_indexed_fields && old_indexed_fields != test.patient.try(:indexed_fields)
        update_entity_in_elasticsearch test.patient, 'patient.uuid'
      end
    end
  end
end
