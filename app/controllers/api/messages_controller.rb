require 'faker'

class Api::MessagesController < ApiController
  include DemoData

  wrap_parameters false
  skip_before_action :doorkeeper_authorize!, only: :create
  skip_before_action :authenticate_user!, only: :create
  skip_before_action :load_current_user_policies, only: :create

  def create
    device = Device.includes(:device_model, :manifest, :institution, :site).find_by_uuid(params[:device_id])
    if !authenticate_create(device)
      head :unauthorized
    else
      data = request.body.read rescue nil
      save_device_message(device, data, true)
    end
  end


  def create_demo
    device = Device.includes(:device_model, :manifest, :institution, :site).find_by_uuid(params[:device_id])
    if !authenticate_create(device)
      head :unauthorized
    else
      data = request.body.read rescue nil
      saved_ok = true
      repeatDemo =  params['repeat_demo'].to_i
      repeatDemo.times do |n|
        changed_data=randomise_device_data(device, data.clone, params['start_datetime'], params['end_datetime'])
        saved_ok = save_device_message(device, changed_data, false)
        break if saved_ok == false
      end

      render :create, :json =>  {} ,:status => :ok if saved_ok == true
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
