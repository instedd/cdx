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

    delegate :institution, :device, :device_message, :client, to: :parent

    def initialize(device_message_processor, parsed_message)
      @parent = device_message_processor
      @parsed_message = parsed_message
      compute_sample_id_reset_policy
      @blender = Blender.new(institution)
    end


    def process
      # Load original test if we are updating one
      test_id = parsed_message.get_in('test', 'core', 'id')
      original_test = test_id && TestResult.within_time(1.year, @parent.device_message.created_at).find_by(test_id: test_id, device_id: device.id)
      test_result = original_test || TestResult.new(institution: institution, device: device)
      test_result.device_messages << device_message
      test_result.test_result_parsed_data << TestResultParsedDatum.new(data: @parsed_message)

      test_blender = @blender.load(test_result)

      # Merge new attributes and sample id
      sample_id = parsed_message.get_in('sample', 'core', 'id').try(:to_s)
      test_blender.merge_attributes attributes_for('test').merge(sample_id: sample_id)

      # Re-assign each entity if present and does not match the original test's
      parent_blenders = {}
      [Sample, Encounter, Patient].each do |klazz|

        original_entity_id = entity_id_for(original_test, klazz)
        new_entity_id = parsed_message.get_in(klazz.entity_scope, (klazz == Patient ? 'pii' : 'core'), 'id').try(:to_s)
        entity_id_does_not_match = original_entity_id && new_entity_id && original_entity_id != new_entity_id

        new_entity = find_entity_by_id(klazz, new_entity_id)
        original_blender = test_blender.send(klazz.entity_scope)

        new_entity ||= klazz.new(institution: institution) if entity_id_does_not_match || original_blender.nil?

        parent_blenders[klazz] = if new_entity
          @blender.load(new_entity)
        else
           original_blender
        end

        @blender.set_parent(test_blender, parent_blenders[klazz])
      end

      # Merge entity attributes from this device message
      [Sample, Encounter, Patient].each do |klazz|
        parent_blenders[klazz].merge_attributes attributes_for(klazz.entity_scope)
      end

      # Commit changes
      @blender.save_and_index!
    end

    private

    def find_entity_by_id(klass, entity_id)
      return nil if entity_id.nil?
      query = klass
      query = query.within_time(entity_reset_time_span(klass), @parent.device_message.created_at) if klass != Patient
      query_opts = { institution_id: @parent.institution.id }
      query_opts[:site_id] = @parent.device.site_id unless @parent.device.site_id.nil? || @parent.institution.kind_manufacturer?
      query.find_by_entity_id(entity_id, query_opts)
    end

    def attributes_for(scope)
      keys = {'core' => 'core_fields', 'custom' => 'custom_fields', 'pii' => 'plain_sensitive_data'}
      Hash[keys.map do |msg_key, attr_key|
        [attr_key, parsed_message.get_in(scope, msg_key) || {}]
      end]
    end

    def assign(entity, attributes)
      attributes = attributes.with_indifferent_access
      entity.core_fields = attributes[:core_fields]
      entity.custom_fields = attributes[:custom_fields]
      entity.plain_sensitive_data = attributes[:plain_sensitive_data]
      entity
    end

    def entity_id_for(test, klass)
      return nil if test.nil?
      if klass == Sample
        test.sample_identifier.try(:entity_id)
      else
        test.send(klass.entity_scope).try(:entity_id)
      end
    end

    def compute_sample_id_reset_policy
      sample_id_reset_policy = @parent.device_message.device.site.try(:sample_id_reset_policy)
      @sample_id_reset_time_span =
        case sample_id_reset_policy
        when "monthly"
           1.month
        when "weekly"
          1.week
        else
          1.year
        end
    end

    def entity_reset_time_span(entity_class)
      if entity_class == Sample
        @sample_id_reset_time_span
      else
        1.year
      end
    end

  end
end
