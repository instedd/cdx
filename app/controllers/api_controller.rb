class ApiController < ApplicationController
  include ApplicationHelper
  include Policy::Actions

  skip_before_filter :verify_authenticity_token
  skip_before_action :authenticate_user!
  before_action :authenticate_api_user!

  def create
    device = Device.includes(:manifests, :institution, :laboratories, :locations).find_by_secret_key(params[:device_uuid])
    event = Event.create_or_update_with device, request.body.read

    if event.index_failed?
      render :status => :unprocessable_entity, :json => { :errors => event.index_failure_reason }
    else
      head :ok
    end
  end

  def events
    body = Oj.load(request.body.read) || {}
    result = Cdx::Api::Elasticsearch::Query.new(params.merge(body)).execute
    respond_to do |format|
      format.csv do
        build_csv result["events"]
        render :layout => false
      end
      format.json { render_json result }
    end
  end

  def custom_fields
    event = Event.find_by_uuid(params[:event_uuid])
    render_json "uuid" => params[:event_uuid], "custom_fields" => event.custom_fields
  end

  def pii
    event = Event.find_by_uuid(params[:event_uuid])
    render_json "uuid" => params[:event_uuid], "pii" => event.decrypt.sensitive_data
  end

  def playground
    @devices = Device.all
  end

  def build_csv events
    @csv_options = { :col_sep => ',' }
    @csv_builder = EventCSVBuilder.new(events)
    @filename = "Events-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
  end

  def schema_endpoint event_structure
  end

end
