include Alerts

class DailyAlertJob
  include Sidekiq::Worker

  def perform   
#   alert_history_check(1.hour)
 alert_history_check(1.day, Alert.per_day)
  end
end

# note: an alternative gem for scheduling cron jobs could be:  http://github.com/javan/whenever but
# the advantage of gem "sidekiq-cron" is that it appears in the sidekiq web url , http://localhost:3000/sidekiq/cron

Sidekiq::Cron::Job.create(name: 'Alert Hourly - daily 12:15am', cron: '15 0 * * *', klass: 'DailyAlertJob')   #run daily at 15 after midnight

