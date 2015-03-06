class Api::EventsController < ApiController
  def create
    device = Device.includes(:manifests, :institution, :laboratories, :locations).find_by_secret_key(params[:device_id])
    data = request.body.read rescue nil

    event = DeviceEvent.new(device:device, plain_text_data: data)

    if event.save
      if event.index_failed?
        render :status => :unprocessable_entity, :json => { :errors => event.index_failure_reason }
      else
        event.process
        render :status => :ok, :json => { :event => event.parsed_event }
      end
    else
      render :status => :unprocessable_entity, :json => { :errors => event.errors.full_messages.join(', ') }
    end
  end

  def upload
    events = CSVEventParser.new.load_for_device request.body.read, params[:device_id] # TODO fix this
    render :status => :ok, :json => { events: events}
  end

  def index
    params.delete(:event)
    body = Oj.load(request.body.read) || {}
    query = Event.query(params.merge(body), current_user)
    respond_to do |format|
      format.csv do
        build_csv 'Events', query.csv_builder
        render :layout => false
      end
      format.json { render_json query.result }
    end
  end

  def custom_fields
    event = Event.includes(:sample).find_by_uuid(params[:id])
    render_json "uuid" => params[:id], "custom_fields" => event.custom_fields.deep_merge(event.sample.custom_fields)
  end

  def pii
    event = Event.includes(:sample).find_by_uuid(params[:id])
    render_json "uuid" => params[:id], "pii" => event.plain_sensitive_data.deep_merge(event.sample.plain_sensitive_data)
  end

  def schema
    schema = EventsSchema.for params["locale"], params["assay_name"]
    respond_to do |format|
      format.json { render_json schema.build }
    end
  rescue ActiveRecord::RecordNotFound => ex
    render :status => :unprocessable_entity, :json => { :errors => ex.message } and return
  end
end
