class TestResultsController < ApplicationController
  add_breadcrumb 'Results', :test_results_path

  def index
    @combo_laboratories = authorize_resource(Laboratory, "cdpx:readLaboratory")

    query = {}
    query["laboratory"] = params["laboratory"] if params["laboratory"].present?
    query["condition"] = params["condition"] if params["condition"].present?
    url = "#{Settings.backend}/api/results?#{query.to_query}"

    @test_results = JSON.parse RestClient.get(url)
    @institutions = indexed_model @test_results, Institution, "institution_id"
    @laboratories = indexed_model @test_results, Laboratory, "laboratory_id"
    @devices = indexed_model @test_results, Device, "device_uuid", "secret_key"
  end

  private

  def indexed_model(test_results, model, es_field, db_field = "id")
    ids = @test_results.map { |result| result[es_field] }
    model.where(db_field => ids).index_by { |model| model[db_field] }
  end
end
