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

  # TODO : Normalize by assay name to avoid keeping manifests in main memory.
  def schema
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

  private

  def find_suitable_manifest target_field, value
    ms = Manifest.all.select { |m| suitable_manifest(Oj.load(m.definition), target_field, params["assay_name"]) }
    ms.last
  end

  def suitable_manifest manifest, target_field, value
    field = manifest["field_mapping"].detect { |f| f["target_field"] == target_field }
    valid_values = []
    if field["options"]
      valid_values = field["options"]
    end
    valid_values.include? value
  end
end
