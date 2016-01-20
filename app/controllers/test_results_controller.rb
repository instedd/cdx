class TestResultsController < ApplicationController
  include Policy::Actions

  before_filter :load_filter_resources

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def index
    @display_as = params["display_as"] || "test"
    @display_as = "test" if @display_as != "test" && @display_as != "test_order"

    @results = Cdx::Fields.test.core_fields.find { |field| field.name == 'result' }.options
    @conditions = Condition.all.map &:name
    @date_options = date_options_for_filter

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

        @filter["device.uuid"] = @devices.first.uuid if @devices.size == 1

        @can_create_encounter = check_access(@navigation_context.institution.sites, CREATE_SITE_ENCOUNTER).size > 0

        execute_query
      end

      format.csv do
        filename = "#{@display_as.pluralize.capitalize}-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
        headers["Content-Type"] = "text/csv"
        headers["Content-disposition"] = "attachment; filename=#{filename}"
        self.response_body = execute_csv_query(filename)
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
    if @display_as == "test"
      create_filter_for_test
    else
      create_filter_for_test_order
    end
  end

  def create_filter_for_test
    filter = create_filter_for_navigation_context
    filter["device.uuid"] = params["device.uuid"] if params["device.uuid"].present?
    filter["test.assays.condition"] = params["test.assays.condition"] if params["test.assays.condition"].present?
    filter["test.assays.result"] = params["test.assays.result"] if params["test.assays.result"].present?
    filter["sample.id"] = params["sample.id"] if params["sample.id"].present?
    filter["since"] = params["since"] if params["since"].present?
    filter
  end

  def create_filter_for_test_order
    filter = create_filter_for_navigation_context
    filter["encounter.uuid"] = params["encounter.id"] if params["encounter.id"].present?
    # filter["device.uuid"] = params["device.uuid"] if params["device.uuid"].present?
    filter["encounter.diagnosis.condition"] = params["test.assays.condition"] if params["test.assays.condition"].present?
    filter["encounter.diagnosis.result"] = params["test.assays.result"] if params["test.assays.result"].present?
    # filter["sample.id"] = params["sample.id"] if params["sample.id"].present?
    filter["since"] = params["since"] if params["since"].present?
    filter
  end

  def create_filter_for_navigation_context
    filter = {}
    filter["institution.uuid"] = @navigation_context.institution.uuid if @navigation_context.institution
    # site.path is used in order to select entitites of descending sites also
    filter["site.path"] = @navigation_context.site.uuid if @navigation_context.site
    filter
  end

  def execute_query
    if @display_as == "test"
      execute_test_query
    else
      execute_encounter_query
    end
  end

  def execute_test_query
    result = TestResult.query(@query, current_user).execute
    @total = result["total_count"]
    @tests = result["tests"]
  end

  def execute_encounter_query
    result = Encounter.query(@query, current_user).execute
    @total = result["total_count"]
    @tests = result["encounters"]
  end

  def execute_csv_query(filename)
    if @display_as == "test"
      execute_csv_test_query(filename)
    else
      execute_csv_test_order_query(filename)
    end
  end

  def execute_csv_test_query(filename)
    query = TestResult.query(@query, current_user)
    EntityCsvBuilder.new("test", query, filename)
  end

  def execute_csv_test_order_query(filename)
    query = Encounter.query(@query, current_user)
    self.response_body = EntityCsvBuilder.new("encounter", query, filename)
  end

  def load_filter_resources
    _institutions, @sites, @devices = Policy.condition_resources_for(QUERY_TEST, TestResult, current_user).values
    @sites = @sites.within(@navigation_context.entity)
    @devices = @devices.within(@navigation_context.entity)
    @devices_by_uuid = @devices.index_by &:uuid
  end
end
