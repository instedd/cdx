class TestResultsController < ApplicationController
  def index
    @combo_laboratories = check_access(Laboratory, READ_LABORATORY)

    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    offset = (@page - 1) * @page_size

    query = {}
    query["page_size"] = @page_size
    query["offset"] = offset
    query["laboratory.id"] = params["laboratory"] if params["laboratory"].present?
    query["test.assays.condition"] = params["condition"] if params["condition"].present?

    result = TestResult.query(query, current_user).result
    @total = result["total_count"]
    @tests = result["tests"]
  end
end
