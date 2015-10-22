class DailyDemoData
  include Sidekiq::Worker
  include DemoData

  #just paste here, we can move this value into an env setting once we start to use this tool 
  def get_repeat_demo_per_device
      1000
  end
  
##
# Note: it is assumed that rake demodata:generate has been called to load the seeds data generated.
#
# if say 1000 daily testresults are needed per device, then loop over the device templates (only two at the moment)
  def perform   

    #in case a job is stuck in the redis queue double check again it is not supposed to run to be 100% sure for production!
    # and check seed data is intialised
    if use_demo_data? and demo_seed_data?
      repeat_demo_per_device =get_repeat_demo_per_device;    
      
      #use the demo templates in db/seeds/manifests_demo_template
      device_list =[ {device: 'demo-device_cepheid', template: 'cepheid.json'},{device: 'demo-device1_fifo', template: 'fio.xml'}]   

      device_list.each do |device_list_info| 
        device = Device.includes(:device_model, :manifest, :institution, :site).find_by_name(device_list_info[:device]) 
        data= IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests_demo_template', device_list_info[:template]))

        repeat_demo_per_device.times do |n|     
          changed_data=randomise_device_data(device, data.clone)
          device_message = DeviceMessage.new(device: device, plain_text_data: changed_data)

          save_error=0;
          if device_message.save
            if device_message.index_failed?
              save_error=1
              Rails.logger.error 'demo device_message.index_failed:' + device_list_info[:device]
            else
              device_message.process
            end
          else
            save_error=2
            Rails.logger.error 'demo device saving error:' + device_list_info[:device]
          end

          break if save_error > 0
        end

      end
    end
  end


private

  
  ##
  # basic check if see if demo seed data has been entered by the rake command demodata:generate
  #
  def demo_seed_data?
    device = Device.includes(:device_model, :manifest, :institution, :site).find_by_name('demo-device_cepheid')
    if device != nil
      return true
    else
      Rails.logger.error 'NO Demo Seed Data'
      return false
    end
  end
  
end



# if set to turn then generate demo data, this is not supposed to be used for production only a demo system
def use_demo_data?
  ENV['USE_DEMO_DATA'] || Settings.use_demo_data
end

# note: an alternative gem for scheduling cron jobs could be:  http://github.com/javan/whenever but
# the advantage of gem "sidekiq-cron" is that it appears in the sidekiq web url , http://localhost:3000/sidekiq/cron
if use_demo_data?
  Sidekiq::Cron::Job.create(name: 'Demo Data - daily 12:15am', cron: '15 0 * * *', klass: 'DailyDemoData')   #run daily at 15 after midnight
end
