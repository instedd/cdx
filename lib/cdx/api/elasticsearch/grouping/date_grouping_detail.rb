require "cdx/api/elasticsearch/grouping/grouping_detail"

class DateGroupingDetail < GroupingDetail
  attr_reader :interval

  def initialize(name, field_definition, uri_param, interval)
    super name, field_definition, uri_param
    @interval = interval
  end

  def to_es
    format = case interval
      when "year"
        "yyyy"
      when "month"
        "yyyy-MM"
      when "week"
        "x-'W'w"
      when "day"
        "yyyy-MM-dd"
      else
        raise "Invalid time interval: #{interval}"
    end

    {count: {date_histogram: {field: field_definition.name, interval: interval, format: format}}}
  end

  def yield_bucket(bucket)
    value = bucket[:key_as_string]

    # Pad week with a zero if it's less than ten
    if @interval == "week"
      value =~ /(\d+)-W(\d+)/
      year, week = $1.to_i, $2.to_i
      value = "%s-W%02d" % [year, week]
    end

    {name => value}
  end
end
