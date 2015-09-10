module TestResultsHelper
  def format_datetime(value)
    return nil unless value
    Time.parse(value).strftime("%Y-%m-%d %H:%M")
  end

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
      results = test["test"]["assays"].map {|assay| "#{assay["name"]}: #{assay["result"]}"}
      if web
        results.join("<br>").html_safe
      else
        results.join(", ")
      end
    when "test.start_time", "test.end_time"
      format_datetime(value)
    else
      value
    end
  end

  def each_column
    yield "test.name", "Name", true
    yield "test.assays", "Result", false
    yield "institution.name", "Institution", false if institutions.size > 1
    yield "laboratory.name", "Laboratory", false if laboratories.size > 1
    yield "device.name", "Device", false if devices.size > 1
    yield "sample.id", "Sample Id", true
    yield "encounter.id", "Encounter Id", true
    yield "test.start_time", "Start Time", true
    yield "test.end_time", "End Time", true
  end
end
