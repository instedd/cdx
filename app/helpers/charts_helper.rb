module ChartsHelper
  def query_site_tests_chart
    results = Reports::Site.process(current_user, @navigation_context, options) 
    found_data = results.sort_by_site.data
    all_sites = check_access(Site.within(@navigation_context.entity), Policy::Actions::READ_SITE)
    sites=all_sites.map { | site | [site.name,0] }
    sites.each do | site | 
      found_data.each do | found_site_data |  
        if site[0].include? found_site_data[0]
          site[1] = found_site_data[1]
        end
      end   
    end 
    return sites
  end
 
  
  def query_devices_not_reporting_chart
    @devices = check_access(Device.within(@navigation_context.entity), Policy::Actions::READ_DEVICE)
    if options["since"] !=nil
      since=options["since"]
    else
      since = (Time.now - 12.months).strftime('%Y-%m-%d')
    end
        
    data=[]
    @devices.each do |device| 
      if options["date_range"] ==nil
        day_range =  (Date.parse(Time.now.strftime('%Y-%m-%d')) -  Date.parse(since) ).to_i
        device_message = DeviceMessage.where(:device_id => device.id).where("created_at > ?", since).order(:created_at).first
      else
        day_range = ( Date.parse(options["date_range"]["start_time"]["lte"]) -  Date.parse(options["date_range"]["start_time"]["gte"]) ).to_i
        device_message = DeviceMessage.where(:device_id => device.id).where("created_at > ? and created_at < ?",options["date_range"]["start_time"]["lge"],options["date_range"]["start_time"]["lte"]).order(:created_at).first
      end
      
      if device_message==nil
        data << [device.name, day_range]
      else
        days_diff = ( (Time.now - (device_message.created_at) ) / (1.day)).round
        data << [device.name, days_diff]
      end
    end
    
    data
  end
  
  
  def devices_reporting_chart
    results = Reports::Devices.process(current_user, @navigation_context, options)
    return results.sort_by_month if results.number_of_months > 1
    return results.sort_by_day
  end

  def errors_by_code
    Reports::Grouped.by_error_code(current_user, @navigation_context, options)
  end


  def error_codes_by_device
    data = Reports::DeviceErrorCodes.process(current_user, @navigation_context, options) 
    data.get_device_location_details      
  end

  def outstanding_orders
    data = Reports::OutstandingOrders.process(current_user, @navigation_context, options) 
    data.latest_encounter
  end
  

  def errors_by_device_chart
    results = Reports::DeviceErrors.process(current_user, @navigation_context, options)
    return results.sort_by_month if results.number_of_months > 1
    return results.sort_by_day
  end

  def devices_grouped
    Reports::Grouped.by_device(current_user, @navigation_context, options)
  end

  def errors_by_model_chart
    results = Reports::ModelErrors.process(current_user, @navigation_context, options)
    return results.sort_by_month if results.number_of_months > 1
    return results.sort_by_day
  end

  def errors_by_model
    Reports::Grouped.by_model(current_user, @navigation_context, options)
  end

  def successful_tests_chart
    results = Reports::Successful.process(current_user, @navigation_context, options)
    return results.sort_by_month if results.number_of_months > 1
    return results.sort_by_day
  end

  def unsuccessful_tests_chart
    options['test.status'] = 'invalid,error,no_result,in_progress'
    results = Reports::Unsuccessful.process(current_user, @navigation_context, options)
    return results.sort_by_month if results.number_of_months > 1
    return results.sort_by_day
  end

  def successful_tests
    Reports::Grouped.by_successful(current_user, @navigation_context, options)
  end

  def unsuccessful_tests
    Reports::Grouped.by_unsuccessful(current_user, @navigation_context, options)
  end

  def errors_by_not_successful
    Reports::Grouped.by_unsuccessful(current_user, @navigation_context, options)
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
    results = Reports::AllTests.process(current_user, @navigation_context, options)
    return results.sort_by_month if results.number_of_months > 1
    return results.sort_by_day
  end

  def tests_by_status
    Reports::Grouped.by_status(current_user, @navigation_context, options)
  end

  def days_since
    end_date.jd - start_date.jd
  end

  def number_of_months
    (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
  end

  def start_date
    params['range'] ? Date.parse(params['range']['start_time']['gte']) : since
  end

  def end_date
    params['range'] ? Date.parse(params['range']['start_time']['lte']) : Date.today
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
    results = Reports::Errors.process(current_user, @navigation_context, options)
    return results.sort_by_month if results.number_of_months > 1
    return results.sort_by_day
  end

  def since
    params['since'] ? Date.parse(params['since']) : Date.today - 1.year
  end
end
