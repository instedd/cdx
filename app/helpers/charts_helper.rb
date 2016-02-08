module ChartsHelper
  def query_tests_chart
    Reports::AllTests.process(current_user, @navigation_context).sort_by_month
  end

  def tests_by_name
    Reports::AllTests.by_name(current_user, @navigation_context)
  end
end
