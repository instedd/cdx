module ChartsHelper
  def errors_by_code
    Reports::Errors.by_code(current_user, @navigation_context, options)
  end

  def errors_by_device
    Reports::Devices.by_device(current_user, @navigation_context, options)
  end

  def errors_by_model
    Reports::Errors.by_model(current_user, @navigation_context, options)
  end

  def errors_by_successful
    Reports::Errors.by_successful(current_user, @navigation_context, options)
  end
  
  def errors_by_not_successful
    Reports::Errors.by_not_successful(current_user, @navigation_context, options)
  end
  
  def chart_heading
    stdate = start_date.strftime("%a %d %b %Y")
    endate = end_date.strftime("%a %d %b %Y")
    if days_since <= 7
      message = "in the previous #{days_since} days"
    else
      message = "between #{stdate} and #{endate}"
    end
    return message
  end

  def query_tests_chart
    data = Reports::AllTests.process(current_user, @navigation_context, options)
    return data.sort_by_month unless params['since']
    return data.sort_by_month(number_of_months - 1) if number_of_months > 1
    return data.sort_by_day(days_since)
  end

  def tests_by_name
    Reports::AllTests.by_name(current_user, @navigation_context, options)
  end

  def days_since
    end_date.jd - start_date.jd
  end

  def number_of_months
    (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
  end

  def start_date
    params['range'] ? Date.parse(params['range']['gte']) : since
  end

  def end_date
    params['range'] ? params['range']['lte'] : Date.today
  end

  def options
    return { 'date_range' => params['range'] } if params['range']
    return { 'since' => params['since'] } if params['since']
    {}
  end

  def options_for_date
    [
      {
        label: 'Previous month',
        value: 1.month.ago.strftime('%Y-%m-%d')
      },
      {
        label: 'Previous week',
        value: 1.week.ago.strftime('%Y-%m-%d')
      },
      {
        label: 'Previous quarter',
        value: 3.months.ago.strftime('%Y-%m-%d')
      },
      {
        label: 'Previous year',
        value: 1.year.ago.strftime('%Y-%m-%d')
      }
    ]
  end

  def query_errors
    data = Reports::Errors.process(current_user, @navigation_context, options)
    return data.sort_by_month unless params['since']
    return data.sort_by_month(number_of_months - 1) if number_of_months > 1
    return data.sort_by_day(days_since)
  end

  def query_errors_data
    query_errors[0]
  end

  def since
    params['since'] ? Date.parse(params['since']) : Date.today - 1.year
  end
end
