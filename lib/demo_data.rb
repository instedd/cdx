module DemoData

  ##
  # Note: it is assumed that rake db:seed has been called to load the seeds data generated.
  #
  # if say 1000 daily testresults are needed per device, then loop over the device templates (only two at the moment)
  def insert_demo_data(repeat_demo_per_device)  

    save_error=nil
    #in case a job is stuck in the redis queue double check again on each job run it is not supposed to run to be 100% sure for production!
    # and check seed data is intialised     

    #check the demo data should be run:ENV added and seed data inserted
    return "setup ENV['USE_DEMO_DATA']" if !use_demo_data? 
    return "run rake db:seed" if !demo_seed_data?
    
    #use the demo templates in jobs/demo_data/manifests_demo_template. 
    device_list =[ {device: 'demo-device_cepheid', template: 'cepheid.json'},{device: 'demo-device1_fifo', template: 'fio.xml'}]   

    device_list.each do |device_list_info| 
      device = Device.includes(:device_model, :manifest, :institution, :site).find_by_name(device_list_info[:device]) 
      data= IO.read(File.join(Rails.root, 'app', 'jobs',  'demo_data', 'manifests_demo_template', device_list_info[:template]))

      repeat_demo_per_device.times do     
        changed_data=randomise_device_data(device, data.clone)
        device_message = DeviceMessage.new(device: device, plain_text_data: changed_data)

        if device_message.save
          if device_message.index_failed?
            save_error="index_failed"
            Rails.logger.error 'demo device_message.index_failed:' + device_list_info[:device]
          else
            device_message.process
          end
        else
          save_error="demo device saving error"
          Rails.logger.error 'demo device saving error:' + device_list_info[:device]
        end

        break if save_error !=nil
      end
    end

    save_error
  end


  ##
  # basic check if see if demo seed data has been entered by the rake db:seed
  #
  def demo_seed_data?
    device = Device.includes(:device_model, :manifest, :institution, :site).find_by_name('demo-device_cepheid')
    if device != nil
      return true
    else
      Rails.logger.error 'No Demo Seed Data'
      return false
    end
  end

  # if set to turn then generate demo data, this is not supposed to be used for production only a demo system
  def use_demo_data?
    ENV['USE_DEMO_DATA'] || Settings.use_demo_data
  end

  def randomise_device_data(device, data, start_datetime='', end_datetime='')
    if data.include?('{result}') 
      result = conditions = ["INVALID", "ERROR", "NO RESULT","MTB NOT DETECTED","Rif Resistance DETECTED","Rif Resistance INDETERMINATE","MTB DETECTED","*"].sample
      data.gsub! '{result}', result
    end

    if data.include?('{system_user}') 
      data.gsub! '{system_user}', system_users.sample
    end

    if data.include?('{sample_id}') 
      data.gsub! '{sample_id}', Faker::Number.number(6) 
    end

    if data.include?('{general_id}') 
      data.gsub! '{general_id}', Faker::Number.number(6) 
    end

    if data.include?('{city}') 
      data.gsub! '{city}', Faker::Address.city
    end

    if data.include?('{event_id}') 
      data.gsub! '{event_id}', Faker::Number.hexadecimal(10)  
    end

    if data.include?('{test_type}') 
      test_types = ["0","*"]
      data.gsub! '{test_type}', test_types.sample 
    end

    if data.include?('{gender_long}')   #fio device
      gender_long_types = ["Male","Female","*"]
      data.gsub! '{gender_long}', gender_long_types.sample 
    end

    if data.include?('{gender}') 
      gender_types = ["M","F","*"]
      data.gsub! '{gender}', gender_types.sample 
    end

    if data.include?('{race}') 
      race_types = ["2054-5","1002-5","2028-9","2076-8","2106-3","2131-1","*"]
      data.gsub! '{race}', race_types.sample 
    end

    if data.include?('{ethnicity}') 
      ethnicity_types = ["hispanic","not_hispanic","*"]
      data.gsub! '{ethnicity}', ethnicity_types.sample 
    end

    if data.include?('{age}') 
      data.gsub! '{age}', Faker::Number.between(5, 90).to_s
    end

    if data.include?('{decimal}') 
      data.gsub! '{decimal}', Faker::Number.between(0, 100).to_s
    end

    if data.include?('{start_datetime}') 
      #note: end date is the last demo sample , for the sample end time just add 1 minute to the start date for now
      start_datetime = Time.now() if start_datetime.to_s.length==0 
      end_datetime = start_datetime+1.day if end_datetime.to_s.length==0 

      new_start_datetime = Faker::Time.between(start_datetime, end_datetime, :all)
      data.gsub! '{start_datetime}', new_start_datetime.to_time.iso8601.to_s
      data.gsub! '{end_datetime}', (new_start_datetime + 1.minute).to_time.iso8601.to_s if data.include?('{end_datetime}') 
    end

    #specific to the FIO device
    if data.include?('{FIO_Postive_Negative_hrp}') 
      pos_neg_type = ["Postive","Negative"].sample 
      data.gsub! '{FIO_Postive_Negative_hrp}', pos_neg_type
      
      if pos_neg_type == 'Negative'
        data.gsub! '{FIO_decimal_hrp}', 0.to_s
      else
        data.gsub! '{FIO_decimal_hrp}', Faker::Number.between(1, 10).to_s
      end
    end
    if data.include?('{FIO_Postive_Negative_lpdh}') 
      pos_neg_type = ["Postive","Negative"].sample 
      data.gsub! '{FIO_Postive_Negative_lpdh}', pos_neg_type

      if pos_neg_type == 'Negative'
        data.gsub! '{FIO_decimal_lpdh}', 0.to_s
      else
        data.gsub! '{FIO_decimal_lpdh}', Faker::Number.between(1, 10).to_s
      end
    end    
    
    
    return data
  end

  private

  def create_system_users
    users = []
    5.times do
      users << Faker::Name.name
    end
    users
  end

  def system_users
    @system_uers ||= create_system_users
  end
end
