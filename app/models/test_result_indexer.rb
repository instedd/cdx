class TestResultIndexer < EntityIndexer
  attr_reader :test_result

  def initialize test_result
    super("test")
    @test_result = test_result
  end

  def after_index(options) 
    percolate_result = client.percolate index: Cdx::Api.index_name, type: type, id: test_result.uuid

    percolate_result["matches"].each do |match|
      subscriber_id = match["_id"]

      #TODO   do we remove the subscriber code, needed any more??
      if subscriber_id.include? 'alert'
        #the alert id is in this format: alert_{alertID}
        subscriber_id.slice! "alert_"
        alert = Alert.includes(:alert_recipients).find(subscriber_id)
        
        if alert.enabled
          AlertJob.perform_later subscriber_id, test_result.uuid
        end
      else
        NotifySubscriberJob.perform_later subscriber_id, test_result.uuid
      end
    end
  end

  def document_id
    test_result.uuid
  end

  def type
    'test'
  end

  def fields_to_index
    return {
      'test'        => test_fields(test_result),
      'device'      => device_fields(test_result.device),
      'location'    => location_fields(test_result.device.site.try(:location, ancestors: true)),
      'institution' => institution_fields(test_result.device.institution),
      'site'        => site_fields(test_result.device.site),
      'sample'      => sample_fields(test_result.sample),
      'encounter'   => encounter_fields(test_result.encounter),
      'patient'     => patient_fields(test_result.patient)
    }
  end

end
