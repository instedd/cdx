require "alerts"
include Alerts

class MonthlyAlertJob
  include Sidekiq::Worker

  def perform
    alert_history_check(1.month, Alert.aggregation_frequencies["month"])
  end
end
