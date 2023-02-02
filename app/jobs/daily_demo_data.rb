include DemoData

class DailyDemoData
  include Sidekiq::Worker

  #just paste here, we can move this value into an env setting once we start to use this tool
  def get_repeat_demo_per_device
    1000
  end

  ##
  # Note: it is assumed that rake db:ssed has been called to load the seeds data generated.
  #
  # if say 1000 daily testresults are needed per device, then loop over the device templates (only two templates at the moment)
  def perform
    insert_demo_data(get_repeat_demo_per_device)
  end

end

if use_demo_data?
  # run daily at 15 after midnight
  Sidekiq::Cron::Job.create(name: 'Demo Data - daily 12:15am', cron: '15 0 * * *', klass: 'DailyDemoData')
end
