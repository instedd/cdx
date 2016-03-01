module ChartsHelper
  def errors_by_code
    Reports::Errors.by_code(current_user, @navigation_context)
  end
  
  def errors_by_device
    Reports::Devices.by_device(current_user, @navigation_context)
  end

  def query_tests_chart
    Reports::AllTests.process(current_user, @navigation_context).sort_by_month
  end

  def tests_by_name
    Reports::AllTests.by_name(current_user, @navigation_context)
  end

  def query_errors
    Reports::Errors.process(current_user, @navigation_context).sort_by_month
  end

  def query_errors_users
    query_errors[1]
  end

  def query_errors_data
    query_errors[0]
  end
end
