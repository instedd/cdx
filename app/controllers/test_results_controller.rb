class TestResultsController < ApplicationController
  def index
    @laboratories = check_access(Laboratory, QUERY_TEST)
    @institutions = check_access(Institution, QUERY_TEST)
    @devices = check_access(Device, QUERY_TEST)
    @results = Cdx.core_fields.find { |field| field.name == 'result' }.options
    @conditions = Condition.all.map &:name
    @date_options = [["Previous month", 1.month.ago.beginning_of_month], ["Previous week", 1.week.ago.beginning_of_week],["Previous year", 1.year.ago.beginning_of_year]]

    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    offset = (@page - 1) * @page_size

    @filter = {}
    @filter["institution.uuid"] = params["institution.uuid"] if params["institution.uuid"].present?
    @filter["laboratory.uuid"] = params["laboratory.uuid"] if params["laboratory.uuid"].present?
    @filter["test.assays.condition"] = params["test.assays.condition"] if params["test.assays.condition"].present?
    @filter["device.uuid"] = params["device.uuid"] if params["device.uuid"].present?
    @filter["test.assays.condition"] = params["test.assays.condition"] if params["test.assays.condition"].present?
    @filter["test.assays.result"] = params["test.assays.result"] if params["test.assays.result"].present?
    @filter["sample.id"] = params["sample.id"] if params["sample.id"].present?
    @filter["since"] = params["since"] if params["since"].present?

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

