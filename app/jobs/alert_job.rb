class AlertJob < ActiveJob::Base
  queue_as :default

  def perform(alert_id, test_elasticsearch_id)    
    alertHistory = AlertHistory.new
    alert_id.slice! "alert_"
    @alert = Alert.find(alert_id)
    
    alertHistory.alert = @alert
    alertHistory.user = @alert.user
    testResult = TestResult.find_by_uuid(test_elasticsearch_id)
    alertHistory.test_result = testResult
    alertHistory.save!

    #TODO, need to inform poirot  for example look at:
    # test = TestResultQuery.find_by_elasticsearch_id(test_elasticsearch_id)
    # subscriber.notify_test(test)

    AlertMailer.alert_email(@alert).deliver_now

    #TODO ,maybe use  AlertMailer.alert_email(@alert).deliver_later
  end
end
