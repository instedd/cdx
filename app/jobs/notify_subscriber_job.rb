class NotifySubscriberJob < ActiveJob::Base
  queue_as :default

  def perform(subscriber_id, test_uuid)
    subscriber = Subscriber.includes(:filter => :user).find(subscriber_id)
    test = TestResult.query({"test.uuid" => test_uuid}, subscriber.filter.user).execute["tests"].first
    subscriber.notify_test(test)
  end
end
