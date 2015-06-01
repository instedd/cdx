class TestResultsController < ApplicationController
  add_breadcrumb 'Results', :test_results_path

  def index
    @combo_laboratories = authorize_resource(Laboratory, READ_LABORATORY)

    query = {}
    query["laboratory"] = params["laboratory"] if params["laboratory"].present?
    query["condition"] = params["condition"] if params["condition"].present?

    @tests = Cdx::Api::Elasticsearch::Query.new(query).execute["events"]
    @institutions = indexed_model Institution, "institution_id"
    @laboratories = indexed_model Laboratory, "laboratory_id"
    @devices = indexed_model Device, "device_uuid", "uuid"
  end

  private

  def indexed_model(model, es_field, db_field = "id")
    ids = @tests.map { |test| test[es_field] }
    model.where(db_field => ids).index_by { |model| model[db_field] }
  end
end
