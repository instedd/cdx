class Api::EncountersController < ApiController
  wrap_parameters false

  def index
    params.delete(:format)
    params.delete(:controller)
    params.delete(:action)
    body = Oj.load(request.body.read) || {}
    filters = params.merge(body)
    query = Encounter.query(filters, current_user)
    respond_to do |format|
      format.csv do
        build_csv 'Encounters', query.csv_builder
        render :layout => false
      end
      format.json { render_json query.execute }
    end
  end

  def pii
    encounter = Encounter.find_by_uuid(params[:id])
    render_json "uuid" => params[:id], "pii" => encounter.pii_data
  end

  def schema
    schema = EncountersSchema.new params["locale"]
    respond_to do |format|
      format.json { render_json schema.build }
    end
  end
end
