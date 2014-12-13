class Api::EventsController < ApiController
  def create
    device = Device.includes(:manifests, :institution, :laboratories, :locations).find_by_secret_key(params[:device_id])
    event, saved = Event.create_or_update_with device, request.body.read

    if saved
      if event.index_failed?
        render :status => :unprocessable_entity, :json => { :errors => event.index_failure_reason }
      else
        render :status => :ok, :json => { :event => event.indexed_body }
      end
    else
      render :status => :unprocessable_entity, :json => { :errors => event.errors }
    end
  end

  def upload
    device = Device.includes(:manifests, :institution, :laboratories, :locations).find_by_secret_key(params[:device_id])
    raw_events = CSVEventParser.new.load_all request.body.read
    events = raw_events.map do |raw_event|
      raw_event = CSVEventParser.new.dump raw_event
      Event.create_or_update_with device, raw_event
    end
    events = events.map do |event|
     {event: event[0].indexed_body, saved: event[1], errors: event[0].errors, index_failure_reason: event[0].index_failure_reason}
    end
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
    event = Event.find_by_uuid(params[:id])
    render_json "uuid" => params[:id], "custom_fields" => event.custom_fields
  end

  def pii
    event = Event.find_by_uuid(params[:id])
    render_json "uuid" => params[:id], "pii" => event.decrypt.sensitive_data
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
