include Alerts

class MonthlyAlertJob
  include Sidekiq::Worker

  def perform
    alert_history_check(1.month, Alert.aggregation_frequencies["month"])
  end
end

Sidekiq::Cron::Job.create(name: 'Alert Monthly - daily 12:15am', cron: '35 0 * * *', klass: 'MonthlyAlertJob')   #run daily at 35 after midnight

#Sidekiq::Cron::Job.create(name: 'Alert Monthly - 10mins 12:15am', cron: '*/5 * * * *', klass: 'MonthlyAlertJob') 
