class ApiController < ActionController::Base
  include ApplicationHelper

  def render_json(object, params={})
    render params.merge(text: object.to_json_oj, content_type: 'text/json')
  end

  def create
    device = Device.includes(:manifests).includes(:institution).includes(:laboratories).includes(:locations).find_by_secret_key(params[:device_uuid])
    Event.create_or_update_with device, request.body.read
    head :ok
  end

  def events
    body = Oj.load(request.body.read) || {}
    result = Event.query(params.merge(body))
    render_json result
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
end
