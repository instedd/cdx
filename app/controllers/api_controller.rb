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
    query = Cdx::Api::Elasticsearch::Query.new(params.merge(body))
    result = query.execute
    respond_to do |format|
      format.csv do
        build_csv 'Events', Event.csv_builder(query, result["events"])
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
    @devices = check_access(Device, READ_DEVICE)
  end

  def build_csv prefix, builder
    @csv_options = { :col_sep => ',' }
    @csv_builder = builder
    @filename = "#{prefix}-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
  end

  def build_laboratories_csv elements
    build_csv elements, 'Laboratories'
  end

  def build_events_csv elements
    build_csv elements, 'Events'
  end

  # TODO : Normalize by assay name to avoid keeping manifests in main memory.
  def capabilities
    manifest = find_suitable_manifest("assay_name", params["assay_name"])
    if !manifest
      render :status => :manifest_not_found, :json => { :errors => "0 Manifests matches with '#{params["assay_name"]}' " } and return
    end
    field_mapping = Oj.load(manifest.definition)["field_mapping"]
    schema = Capability.new field_mapping, params["assay_name"], params["locale"]
    respond_to do |format|
      format.json { render_json schema.to_json }
    end
  end

  def laboratories
    @laboratories = if params[:institution_id]
      Institution.find(params[:institution_id]).laboratories
    else
      Laboratory.all
    end

    @laboratories = check_access(@laboratories, READ_LABORATORY).map do |lab|
      {id: lab.id, name: lab.name, location: lab.location_id}
    end

    respond_to do |format|
      format.csv do
        build_csv 'Laboratories', CSVBuilder.new(@laboratories, column_names: ["id", "name", "location"])
        render :layout => false
      end
      format.json do
        render_json({
          total_count: @laboratories.size,
          laboratories: @laboratories
        })
      end
    end
  end

  private

  def find_suitable_manifest target_field, value
    ms = Manifest.all.select { |m| suitable_manifest(Oj.load(m.definition), target_field, params["assay_name"]) }
    ms.last
  end

  def suitable_manifest manifest, target_field, value
    field = manifest["field_mapping"].detect { |f| f["target_field"] == target_field }
    valid_values = []
    if field["valid_values"] && field["valid_values"]["options"]
      valid_values = field["valid_values"]["options"]
    end
    valid_values.include? value
  end

end
