class TestResultsController < ApplicationController
  def index
    @combo_laboratories = authorize_resource(Laboratory, READ_LABORATORY)

    query = {}
    query["laboratory.id"] = params["laboratory"] if params["laboratory"].present?
    query["test.assays.condition"] = params["condition"] if params["condition"].present?

    @tests = TestResult.query(query, current_user).result["tests"]
  end
end
