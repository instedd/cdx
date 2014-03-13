class Subscriber < ActiveRecord::Base
  belongs_to :work_group

  def enqueue_notification report
    if Rails.env.test?
      SubscriptionDispatcher.new(nil, nil, {report: report, subscriber: self}.to_json).run
    else
      Rabbitmq.active_connection.enqueue report: report, subscriber: self
    end
  end
end
