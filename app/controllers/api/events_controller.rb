class Api::EventsController < ApiController
  wrap_parameters false
  skip_before_action :authenticate_api_user!, only: :create
  skip_before_action :load_current_user_policies, only: :create

  def create
    if current_user && !params[:authentication_token]
      devices_scope = current_user.devices
    else
      devices_scope = Device.all
    end

    device = devices_scope.includes(:manifests, :institution, :laboratories).find_by_uuid(params[:device_id])

    if authenticate_create(device)
      data = request.body.read rescue nil
      device_event = DeviceEvent.new(device: device, plain_text_data: data)

      if device_event.save
        if device_event.index_failed?
          render :status => :unprocessable_entity, :json => { :errors => device_event.index_failure_reason }
        else
          device_event.process
          render :status => :ok, :json => { :events => device_event.parsed_events }
        end
      else
        render :status => :unprocessable_entity, :json => { :errors => device_event.errors.full_messages.join(', ') }
      end
    else
      head :unauthorized
    end
  end

  def index
    params.delete(:format)
    params.delete(:controller)
    params.delete(:action)
    body = Oj.load(request.body.read) || {}
    filters = params.merge(body)
    if filters.blank?
      render :status => :unprocessable_entity, :json => { :errors => "The query must contain at least one filter"}
    else
      query = TestResult.query(filters, current_user)
      respond_to do |format|
        format.csv do
          build_csv 'Tests', query.csv_builder
          render :layout => false
        end
        format.json { render_json query.result }
      end
    end
  end

  def custom_fields
    test = TestResult.includes(:sample).find_by_uuid(params[:id])
    render_json "uuid" => params[:id], "custom_fields" => test.custom_fields_data
  end

  def pii
    test = TestResult.find_by_uuid(params[:id])
    render_json "uuid" => params[:id], "pii" => test.pii_data
  end

  def schema
    schema = EventsSchema.for params["locale"], params
    respond_to do |format|
      format.json { render_json schema.build }
    end
  rescue ActiveRecord::RecordNotFound => ex
    render :status => :unprocessable_entity, :json => { :errors => ex.message } and return
  end

  private

  def authenticate_create(device)
    token = params[:authentication_token]
    return true if current_user && !token
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
