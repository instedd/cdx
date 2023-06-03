require "alerts"
include Alerts

class HourlyAlertJob
  include Sidekiq::Worker

  def perform
    alert_history_check(1.hour, Alert.aggregation_frequencies["hour"])
  end
end
