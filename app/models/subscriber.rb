class Subscriber < ActiveRecord::Base
  belongs_to :institution

  def enqueue_notification test_result
    if Rails.env.test?
      SubscriptionDispatcher.new(nil, nil, {test_result: test_result, subscriber: self}.to_json).run
    else
      Rabbitmq.active_connection.enqueue test_result: test_result, subscriber: self
    end
  end
end
