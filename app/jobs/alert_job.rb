include Alerts

class AlertJob < ActiveJob::Base
  queue_as :default

  def perform(alert_id, test_elasticsearch_id)
    alertHistory = AlertHistory.new

    @alert = Alert.includes(:alert_recipients).find(alert_id)
    alertHistory.alert = @alert
    alertHistory.user = @alert.user
    testResult = TestResult.find_by_uuid(test_elasticsearch_id)
    alertHistory.test_result = testResult

    #store that it is only used for alert aggregations if an aggregation type of alert
    if @alert.aggregated?
      alertHistory.for_aggregation_calculation  = true
    end

    alertHistory.save!

    #only inform the recipients if the alert is a per_record type, the background jobs will handle the aggregation
    if @alert.record? and (@alert.email? or @alert.email_and_sms?)
      alert_inform_recipient(@alert, alertHistory)
    end
  end
end
