require "alerts"
include Alerts

class WeeklyAlertJob
  include Sidekiq::Worker

  def perform
    alert_history_check(1.week, Alert.aggregation_frequencies["week"])
  end
end
