include Alerts

class AlertJob < ActiveJob::Base
  queue_as :default

  def perform(alert_id, test_elasticsearch_id)
    alertHistory = AlertHistory.new

    #the id is in this format: alert_{alertID}_{categoryID}

    alert_id.slice! "alert_"
    @alert = Alert.includes(:alert_recipients).find(alert_id)

    #index_parts = alert_id.split('_')
    #alert_index = index_parts[1]
    #@alert = Alert.includes(:alert_recipients).find(index_parts[1])

    alertHistory.alert = @alert
    alertHistory.user = @alert.user
    testResult = TestResult.find_by_uuid(test_elasticsearch_id)
    alertHistory.test_result = testResult

    #store that it is only used for alert aggregations if an aggregation type of alert
    if @alert.aggregated?
      alertHistory.for_aggregation_calculation  = true
    end

    alertHistory.save!

    #TODO, need to inform poirot  for example look at:
    # test = TestResultQuery.find_by_elasticsearch_id(test_elasticsearch_id)
    # subscriber.notify_test(test)

    #only inform the recipients if the alert is a per_record type

    if @alert.record?
      # AlertMailer.alert_email(@alert).deliver_now
      alert_inform_recipient(@alert, alertHistory, 0)
    end

    #TODO ,maybe use  AlertMailer.alert_email(@alert).deliver_later
  end
end
