module TestResultsHelper
  def order_by_column(title, field)
    desc_field = "-#{field}"
    link_order_by = @order_by == field ? desc_field : field

    link = link_to title, params.merge(order_by: link_order_by)
    if @order_by == field
      link.safe_concat(" \u{2191}")
    elsif @order_by == desc_field
      link.safe_concat(" \u{2193}")
    else
      link
    end
  end

  def test_value(test, path)
    path.split(".").inject(test) { |obj, step| obj && obj[step] }
  end

  def formatted_test_value(test, path, web: false)
    value = test_value(test, path)
    case path
    when "test.assays"
      results = test["test"]["assays"] || []
      if web
        (results.map { |result| "<span class=\"#{result["result"]}\">#{result["name"]}</span>" } ).join(" ").html_safe
      else
        (results.map { |assay| "#{assay["name"]}: #{assay["result"]}"}).join(", ")
      end
    when "test.start_time", "test.end_time"
      time_zone = current_user.time_zone
      if current_user.timestamps_in_device_time_zone && (test_device = test["device"]) && (device = @devices_by_uuid[test_device["uuid"]]) && (device_time_zone = device.time_zone)
        time_zone = device_time_zone
      end

      format_datetime(value, time_zone)
    else
      value
    end
  end

  def each_column
    yield "test.name", "Name", true
    yield "test.assays", "Result", false
    yield "institution.name", "Institution", false if @institutions.size > 1
    yield "site.name", "Site", false if @sites.size > 1
    yield "device.name", "Device", false if @devices.size > 1
    yield "sample.id", "Sample Id", true
    yield "encounter.id", "Encounter Id", true
    yield "test.start_time", "Start Time", true
    yield "test.end_time", "End Time", true
  end
end
