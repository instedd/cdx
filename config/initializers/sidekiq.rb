Sidekiq.configure_server do |config|
  config.on(:startup) do
    # run daily at 15 after midnight
    Sidekiq::Cron::Job.create(name: 'Alert Daily - daily 12:15am', cron: '15 0 * * *', klass: 'DailyAlertJob')

    # run daily at 25 after midnight
    Sidekiq::Cron::Job.create(name: 'Alert Weekly - daily 12:15am', cron: '25 0 * * *', klass: 'WeekyAlertJob')

    # run daily at 35 after midnight
    Sidekiq::Cron::Job.create(name: 'Alert Monthly - daily 12:15am', cron: '35 0 * * *', klass: 'MonthlyAlertJob')

    # run hourly
    Sidekiq::Cron::Job.create(name: 'Alert Hourly - hourly', cron: '0 * * * *', klass: 'HourlyAlertJob')

    # run every 30 mins to give more accuracy, +/- 30 mins
    Sidekiq::Cron::Job.create(name: 'Alert Utilization Efficiency - hourly', cron: '*/30 * * * *', klass: 'HourlyUtilizationEfficiencyJob')

    # for manual tests (run every some 2, 5 or 10 mins):
    # Sidekiq::Cron::Job.create(name: 'Alert Utilization Efficiency - hourly', cron: '*/2 * * * *', klass: 'HourlyUtilizationEfficiencyJob')
    # Sidekiq::Cron::Job.create(name: 'Alert Monthly - 10mins 12:15am', cron: '*/5 * * * *', klass: 'MonthlyAlertJob')
    # Sidekiq::Cron::Job.create(name: 'Alert Hourly - 10mins 12:15am', cron: '*/10 * * * *', klass: 'HourlyAlertJob')

    # run daily at 02:00am
    Sidekiq::Cron::Job.create(name: 'Cleanup unused AssayFile', cron: '0 2 * * *', klass: 'CleanupAssayFilesJob')
  end
end
