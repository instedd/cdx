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

    @order_by = params["order_by"] || "test.end_time"
    @query["order_by"] = @order_by

    result = TestResult.query(@query, current_user).result
    @total = result["total_count"]
    @tests = result["tests"]
  end
end

