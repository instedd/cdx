include Alerts

class HourlyAlertJob
  include Sidekiq::Worker

  def perform
    alert_history_check(1.hour, Alert.aggregation_frequencies["hour"])
  end
end

# note: an alternative gem for scheduling cron jobs could be:  http://github.com/javan/whenever but
# the advantage of gem "sidekiq-cron" is that it appears in the sidekiq web url , http://localhost:3000/sidekiq/cron

Sidekiq::Cron::Job.create(name: 'Alert Hourly - hourly', cron: '0 * * * *', klass: 'HourlyAlertJob')   #run each hour

#for test run every 5 mins:
#Sidekiq::Cron::Job.create(name: 'Alert Hourly - 10mins 12:15am', cron: '*/10 * * * *', klass: 'HourlyAlertJob')   #run daily at 15 after midnight
