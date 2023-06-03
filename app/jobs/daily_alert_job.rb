require "alerts"
include Alerts

class DailyAlertJob
  include Sidekiq::Worker

  def perform
    alert_history_check(1.day, Alert.aggregation_frequencies["day"])
  end
end
