class NotifySubscriberJob < ApplicationJob
  queue_as :default

  def perform(subscriber_id, test_elasticsearch_id)
    subscriber = Subscriber.includes(:filter => :user).find(subscriber_id)
    test = TestResultQuery.find_by_elasticsearch_id(test_elasticsearch_id)
    subscriber.notify_test(test)
  end
end
