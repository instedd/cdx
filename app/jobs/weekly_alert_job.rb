require "alerts"
include Alerts

class WeeklyAlertJob
  include Sidekiq::Worker

  def perform
    alert_history_check(1.week, Alert.aggregation_frequencies["week"])
  end
end

Sidekiq::Cron::Job.create(name: 'Alert Weekly - daily 12:15am', cron: '25 0 * * *', klass: 'WeekyAlertJob')   #run daily at 25 after midnight

