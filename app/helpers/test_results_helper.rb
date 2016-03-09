module TestResultsHelper
  def order_by_column(title, field)
    desc_field = "-#{field}"
    link_order_by = @order_by == field ? desc_field : field

    if @order_by == field
      css_class = 'ordered order-asc'
      title = "#{title} ↑"
    elsif @order_by == desc_field
      css_class = 'ordered order-desc'
      title = "#{title} ↓"
    end

    link_to title, params.merge(order_by: link_order_by), class: css_class
  end

  def test_value(test, path)
    path.split(".").inject(test) { |obj, step| obj && obj[step] }
  end

  def formatted_test_value(test, path, web: false)
    value = test_value(test, path)
    case path
    when "test.assays", "encounter.diagnosis"
      scope, field = path.split('.')
      results = test[scope][field] || []
      if web
        (results.map { |result| "<span class=\"assay-result assay-result-#{result["result"]}\">#{result["condition"]}</span>" } ).join(" ").html_safe
      else
        (results.map { |result| "#{result["condition"]}: #{result["result"]}"}).join(", ")
      end
    when "test.start_time", "test.end_time"
      time_zone = current_user.time_zone
      if current_user.timestamps_in_device_time_zone && (test_device = test["device"]) && (device = @devices_by_uuid[test_device["uuid"]]) && (device_time_zone = device.time_zone)
        time_zone = device_time_zone
      end

      @localization_helper.format_datetime_time_zone(value, time_zone)
    when "encounter.start_time", "encounter.end_time"
      @localization_helper.format_datetime_time_zone(value, current_user.time_zone)
    else
      value
    end
  end

  def each_test_column(&block)
    if @display_as == "test"
      each_test_result_column(&block)
    else
      each_test_order_column(&block)
    end
  end

  def each_test_result_column
    time_width = case
    when @sites.size > 1 && @devices.size > 1 then "15%"
    when @sites.size > 1 || @devices.size > 1 then "20%"
    else "25%"
    end

    yield "test.name", "Name", sortable: true, width: "20%"
    yield "test.assays", "Result", sortable: false, width: "20%"
    yield "site.name", "Site", sortable: false, width: "10%" if @sites.size > 1
    yield "device.name", "Device", sortable: false, width: "10%" if @devices.size > 1
    yield "sample.id", "Sample Id", sortable: true, width: "10%"
    yield "test.start_time", "Start Time", sortable: true, width: time_width
    yield "test.end_time", "End Time", sortable: true, width: time_width
  end

  def each_test_order_column
    yield "encounter.uuid", "ID", sortable: true, width: "15%"
    yield "site.name", "Site", sortable: false, width: "20%" if @sites.size > 1
    yield "encounter.diagnosis", "Diagnosis", sortable: false, width: "30%"
    yield "encounter.start_time", "Start Time", sortable: true, width: (@sites.size > 1 ? "15%" : "25%")
    yield "encounter.end_time", "End Time", sortable: true, width: (@sites.size > 1 ? "15%" : "25%")
  end
end
