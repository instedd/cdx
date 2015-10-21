module DemoData

  def randomise_device_data(device, data,start_datetime="", end_datetime="")
    if data.include?('{result}') 
      result = conditions = ["INVALID", "ERROR", "NO RESULT","MTB NOT DETECTED","Rif Resistance DETECTED","Rif Resistance INDETERMINATE","MTB DETECTED","*"].sample
      data.sub! '{result}', result
    end
    if data.include?('{system_user}') 
      data.sub! '{system_user}', 'demo-'+Faker::Name.name 
    end
    if data.include?('{sample_id}') 
      data.sub! '{sample_id}', Faker::Number.number(6) 
    end
    if data.include?('{general_id}') 
      data.sub! '{general_id}', Faker::Number.number(6) 
    end
    if data.include?('{city}') 
      data.sub! '{city}', Faker::Address.city
    end

    if data.include?('{event_id}') 
      data.sub! '{event_id}', Faker::Number.hexadecimal(10)  
    end
    if data.include?('{test_type}') 
      test_types = ["0","*"]
      data.sub! '{test_type}', test_types.sample 
    end

    if data.include?('{gender_long}')   #fio device
      gender_long_types = ["Male","Female","*"]
      data.sub! '{gender_long}', gender_long_types.sample 
    end

    if data.include?('{gender}') 
      gender_types = ["M","F","*"]
      data.sub! '{gender}', gender_types.sample 
    end

    if data.include?('{race}') 
      race_types = ["2054-5","1002-5","2028-9","2076-8","2106-3","2131-1","*"]
      data.sub! '{race}', race_types.sample 
    end
    if data.include?('{ethnicity}') 
      ethnicity_types = ["hispanic","not_hispanic","*"]
      data.sub! '{ethnicity}', ethnicity_types.sample 
    end
    if data.include?('{age}') 
      data.sub! '{age}', Faker::Number.between(5, 90).to_s
    end
    if data.include?('{decimal}') 
      data.sub! '{decimal}', Faker::Number.between(0, 100).to_s
    end

    if data.include?('{start_datetime}') 
      #note: end date is the last demo sample , for the sample end time just add 1 minute to the start date for now
      start_datetime = Time.now() if start_datetime.to_s.length==0 
      end_datetime = start_datetime+1.day if end_datetime.to_s.length==0 

      new_start_datetime = Faker::Time.between(start_datetime, end_datetime, :all)
      data.sub! '{start_datetime}', new_start_datetime.to_time.iso8601.to_s
      data.sub! '{end_datetime}', (new_start_datetime + 1.minute).to_time.iso8601.to_s if data.include?('{end_datetime}') 
    end

    return data
  end


end