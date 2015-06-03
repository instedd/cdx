class Api::TestsController < ApiController
  wrap_parameters false

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
    schema = TestsSchema.for params["locale"], params
    respond_to do |format|
      format.json { render_json schema.build }
    end
  rescue ActiveRecord::RecordNotFound => ex
    render :status => :unprocessable_entity, :json => { :errors => ex.message } and return
  end

end
