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
        "yyyy-'W'w"
      when "day"
        "yyyy-MM-dd"
      else
        raise "Invalid time interval: #{interval}"
    end
    
    {count: {date_histogram: {field: field_definition[:name], interval: interval, format: format}}}
  end

  def yield_bucket(bucket)
    {name => bucket[:key_as_string]}
  end
end