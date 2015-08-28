class TestResultsController < ApplicationController
  def index
    @combo_laboratories = check_access(Laboratory, READ_LABORATORY)

    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    offset = (@page - 1) * @page_size
    
    @filter = {}
    @filter["laboratory.id"] = params["laboratory.id"] if params["laboratory.id"].present?
    @filter["test.assays.condition"] = params["test.assays.condition"] if params["test.assays.condition"].present?

    @query = @filter.dup
    @query["page_size"] = @page_size
    @query["offset"] = offset

    result = TestResult.query(@query, current_user).result
    @total = result["total_count"]
    @tests = result["tests"]
  end
end

