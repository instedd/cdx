class TestResultsController < ApplicationController
  include Policy::Actions

  before_filter :load_filter_resources

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def index
    @results = Cdx::Fields.test.core_fields.find { |field| field.name == 'result' }.options
    @conditions = Condition.all.map &:name
    @date_options = [["Previous month", 1.month.ago.beginning_of_month], ["Previous week", 1.week.ago.beginning_of_week],["Previous year", 1.year.ago.beginning_of_year]]

    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    offset = (@page - 1) * @page_size

    @filter = create_filter
    @query = @filter.dup
    @order_by = params["order_by"] || "test.end_time"
    @query["order_by"] = @order_by

    respond_to do |format|
      format.html do
        @query["page_size"] = @page_size
        @query["offset"] = offset

        @filter["institution.uuid"] = @institutions.first.uuid if @institutions.size == 1
        @filter["site.uuid"] = @sites.first.uuid if @sites.size == 1
        @filter["device.uuid"] = @devices.first.uuid if @devices.size == 1

        result = TestResult.query(@query, current_user).execute
        @total = result["total_count"]
        @tests = result["tests"]
      end

      format.csv do
        query = TestResult.query(@query, current_user)
        filename = "Tests-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
        csv = TestResultsCsvBuilder.new(query, filename)
        @csvfile = csv.build
        send_file(@csvfile.path, filename: filename)
      end
    end

  end

  def show
    @test_result = TestResult.find_by(uuid: params[:id])
    return unless authorize_resource(@test_result, QUERY_TEST)

    @other_tests = @test_result.sample ? @test_result.sample.test_results.where.not(id: @test_result.id) : TestResult.none
    @core_fields_scope = Cdx::Fields.test.core_field_scopes.detect{|x| x.name == 'test'}

    @samples = @test_result.sample_identifiers.reject{|identifier| identifier.entity_id.blank?}.map {|identifier| [identifier.entity_id, Barby::Code93.new(identifier.entity_id)]}
    @show_institution = show_institution?(Policy::Actions::QUERY_TEST, TestResult)
  end

  private

  def create_filter
    filter = {}
    filter["institution.uuid"] = params["institution.uuid"] if params["institution.uuid"].present?
    filter["site.uuid"] = params["site.uuid"] if params["site.uuid"].present?
    filter["test.assays.condition"] = params["test.assays.condition"] if params["test.assays.condition"].present?
    filter["device.uuid"] = params["device.uuid"] if params["device.uuid"].present?
    filter["test.assays.condition"] = params["test.assays.condition"] if params["test.assays.condition"].present?
    filter["test.assays.result"] = params["test.assays.result"] if params["test.assays.result"].present?
    filter["sample.id"] = params["sample.id"] if params["sample.id"].present?
    filter["since"] = params["since"] if params["since"].present?
    filter
  end

  def load_filter_resources
    @institutions, @sites, @devices = Policy.condition_resources_for(QUERY_TEST, TestResult, current_user).values
    @devices_by_uuid = @devices.index_by &:uuid
  end
end
