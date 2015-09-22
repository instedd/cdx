class TestResultsController < ApplicationController
  require 'barby'
  require 'barby/barcode/code_93'

  expose(:laboratories) { check_access(Laboratory, QUERY_TEST) }
  expose(:institutions) { check_access(Institution, QUERY_TEST) }
  expose(:devices) { check_access(Device, QUERY_TEST) }

  def index
    @results = Cdx.core_fields.find { |field| field.name == 'result' }.options
    @conditions = Condition.all.map &:name
    @date_options = [["Previous month", 1.month.ago.beginning_of_month], ["Previous week", 1.week.ago.beginning_of_week],["Previous year", 1.year.ago.beginning_of_year]]

    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    offset = (@page - 1) * @page_size

    @filter = create_filter
    @query = @filter.dup
    @query["page_size"] = @page_size
    @query["offset"] = offset

    @order_by = params["order_by"] || "test.end_time"
    @query["order_by"] = @order_by

    result = TestResult.query(@query, current_user).execute
    @total = result["total_count"]
    @tests = result["tests"]
  end

  def show
    @main_column_width = 6

    @test_result = TestResult.find_by(uuid: params[:id])
    return unless authorize_test_result(@test_result)

    @other_tests = @test_result.sample.test_results.where.not(id: @test_result.id)
    @core_fields_scope = Cdx.core_field_scopes.detect{|x| x.name == 'test'}

    @sample_id = @test_result.sample.core_fields['id']
    @sample_id_barcode = Barby::Code93.new(@sample_id)
  end

  def csv
    @query = TestResult.query(create_filter, current_user)
    @filename = "Tests-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
    @streaming = true
    render csv: true, layout: false
  end

  private def create_filter
    filter = {}
    filter["institution.uuid"] = params["institution.uuid"] if params["institution.uuid"].present?
    filter["laboratory.uuid"] = params["laboratory.uuid"] if params["laboratory.uuid"].present?
    filter["test.assays.condition"] = params["test.assays.condition"] if params["test.assays.condition"].present?
    filter["device.uuid"] = params["device.uuid"] if params["device.uuid"].present?
    filter["test.assays.condition"] = params["test.assays.condition"] if params["test.assays.condition"].present?
    filter["test.assays.result"] = params["test.assays.result"] if params["test.assays.result"].present?
    filter["sample.id"] = params["sample.id"] if params["sample.id"].present?
    filter["since"] = params["since"] if params["since"].present?
    filter
  end
end
