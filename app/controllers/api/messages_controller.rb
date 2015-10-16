require 'Faker'

class Api::MessagesController < ApiController
  wrap_parameters false
  skip_before_action :doorkeeper_authorize!, only: :create

  def create
    device = Device.includes(:device_model, :manifest, :institution, :site).find_by_uuid(params[:device_id])

    if !authenticate_create(device)
      head :unauthorized
    else
      data = request.body.read rescue nil

      if params['repeat_demo'].to_i > 0
        randomise_device_data(params['repeat_demo'].to_i, params['start_datetime'], params['end_datetime'], device, data)
      else
        binding.pry
        save_device_message(device, data, true)
    end
  end
end


  private

 ##
 # save the device test result and redender an error.  
 #
 # if no error occurs [and render_ok=true] then do not render as this is used by 
 # the demo data generator.
 #
 # return true if the data was saved.
 
 def save_device_message(device, data, render_ok)
    device_message = DeviceMessage.new(device: device, plain_text_data: data)
    saved_ok = false
    
    if device_message.save
      if device_message.index_failed?
        render :status => :unprocessable_entity, :json => { :errors => device_message.index_failure_reason }
      else
        device_message.process
        saved_ok = true
         
        #only do a render now if not used to generate demo data
        render :status => :ok, :json => { :messages => device_message.parsed_messages } if render_ok == true
      end
    else
      render :status => :unprocessable_entity, :json => { :errors => device_message.errors.full_messages.join(', ') }
    end 
  
  return saved_ok
  end
  
  
  ##
  # if the input data contained fields such as '{....}' and it is handled here then replace it with random data.
  # we could improve the performance such as with Oj json parsing in the future if ther is a performance issue. 
  # refer to the wiki page to see the syntax that the input data is expected to be in 
  #  
  def randomise_device_data(repeatDemo, start_datetime, end_datetime, device, data_orig)
        
   saved_ok = true;   
   repeatDemo.times do |n|
     
       data = data_orig.clone
       if data.include?('{result}') 
=begin
         conditions = ["inh", "MTB", "rif"]
         condition_result = ["postive", "negative", "postive","postive"]  #put more weight on positive
         condition_result_type=["low", "medium", "high", "low","low"]
         result = conditions.sample + ' '+condition_result.sample + ' '+condition_result_type.sample
=end
         result = conditions = ["INVALID", "ERROR", "NO RESULT","MTB NOT DETECTED","Rif Resistance DETECTED","Rif Resistance INDETERMINATE","MTB DETECTED","*"].sample
         data.sub! '{result}', result
       end
      if data.include?('{system_user}') 
          data.sub! '{system_user}', Faker::Name.name 
      end
      if data.include?('{sample_id}') 
          data.sub! '{sample_id}', Faker::Number.number(6) 
      end
      
      if data.include?('{event_id}') 
         data.sub! '{event_id}', Faker::Number.hexadecimal(10)  
      end
      if data.include?('{test_type}') 
        test_types = ["0","*"]
        data.sub! '{test_type}', test_types.sample 
      end
      
      if data.include?('{gender_long}')   #fifo device
        gender_types = ["Male","Female","*"]
        data.sub! '{gender}', gender_types.sample 
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
        data.sub! '{age}', Faker::Number.between(5, 90)
      end

      if data.include?('{start_datetime}') and data.include?('{end_datetime}') 
        
        #note: end date is the last demo sample , for the sample end time just add 1 minute to the start date for now
        start_datetime = Time.now() if start_datetime.to_s.length==0 
        end_datetime = start_datetime+1.day if end_datetime.to_s.length==0 
        
        new_start_datetime = Faker::Time.between(start_datetime, end_datetime, :all)
        data.sub! '{start_datetime}', new_start_datetime.to_time.iso8601.to_s
        data.sub! '{end_datetime}', (new_start_datetime + 1.minute).to_time.iso8601.to_s
      end


    saved_ok = save_device_message(device, data, false) 
    break if saved_ok == false  
    end
    
    render :create, :json =>  {} ,:status => :ok if saved_ok == true
  end
  
  
  def authenticate_create(device)
    token = params[:authentication_token]
    if current_user && !token
      return authorize_resource(device, REPORT_MESSAGE)
    end
    token ||= basic_password
    return false unless token
    device.validate_authentication(token)
  end

  def basic_password
    ActionController::HttpAuthentication::Basic.authenticate(request) do |user, password|
      password
    end
  end
end
