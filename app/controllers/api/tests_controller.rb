class Api::TestsController < ApiController
  wrap_parameters false

  def index
    params.delete(:format)
    params.delete(:controller)
    params.delete(:action)
    body = Oj.load(request.body.read) || {}
    filters = params.merge(body)
    query = TestResult.query(filters, current_user)
    
    respond_to do |format|
      format.csv do
        build_csv 'Tests', query.csv_builder
        render :layout => false
      end
      format.json { render_json query.execute }
    end
  end

  def pii
    test = TestResult.find_by_uuid(params[:id])
    return unless authorize_resource(test, Policy::Actions::PII_TEST)
    render_json "uuid" => params[:id], "pii" => test.pii_data
  end

  def schema
    schema = TestsSchema.new params["locale"]
    respond_to do |format|
      format.json { render_json schema.build }
    end
  end

end
