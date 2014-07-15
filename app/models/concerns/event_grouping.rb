module EventGrouping
  extend ActiveSupport::Concern

  included do
    def self.query_with_group_by(query, group_by)
      group_by = if (group_by.is_a? String)
        group_by.split ","
      else
        Array(group_by)
      end

      group_by = group_by.map do |field|
        classify_group_by_field field
      end

      # nested fields must appear last in the group by
      group_by = group_by.sort_by do |field|
        field[:type]
      end

      aggregations = process_group_by(group_by)

      client = Elasticsearch::Client.new log: true
      event = client.search(index: "#{Elasticsearch.index_prefix}*", body: {query: query, aggregations: aggregations})

      process_group_by_buckets(event["aggregations"].with_indifferent_access, group_by, [], {}, 0)
    end

    def self.process_group_by(aggregations)
      return Array.new if aggregations.empty?

      count = process_group_by_options(aggregations[0])

      (aggregations[1..-1].inject count do |count, group_by|
        count[:count][:aggregations] = process_group_by_options(group_by)
      end)

      count
    end

    def self.process_nested_group_by(fields)
      count = {
          aggregations: {
            count: {
              terms: {field: "#{fields[0][:name]}.#{fields[0][:sub_fields][:name]}"}
            }
          }
        }
      (fields[1..-1].inject count do |count, group_by|
        count[:aggregations] = {
          aggregations: {
            count: {
              terms: {field: "#{group_by[:name]}.#{group_by[:sub_fields][:name]}"}
            }
          }
        }
      end)
    end

    def self.process_group_by_options(group_by)
      if group_by[:type] == :nested
        if group_by[:sub_fields].is_a? Array and group_by[:sub_fields].size > 1
          return {
            count: {
              nested: {path: group_by[:name]},
              aggs: {
                count: {
                  terms: {field: "#{group_by[:name]}.#{group_by[:sub_fields][0][:name]}"}
                }.merge(process_nested_group_by group_by[:sub_fields][1..-1])
              }
            }
          }
        else
          return {
            count: {
              nested: {path: group_by[:name]},
              aggs: {
                count: {
                  terms: {field: "#{group_by[:name]}.#{group_by[:sub_fields][:name]}"}
                }
              }
            }
          }
        end
      end
      if group_by[:type] == :range
        return {count: {range: {field: group_by[:name], ranges: convert_ranges_to_elastic_search(group_by[:ranges])}}}
      end
      if group_by[:type] == :date
        format = case group_by[:interval]
          when "year"
            "yyyy"
          when "month"
            "yyyy-MM"
          when "week"
            "yyyy-'W'w"
          when "day"
            "yyyy-MM-dd"
          else
            raise "Invalid time interval."
         end
        return {count: {date_histogram: {field: group_by[:name], interval: group_by[:interval], format: format}}}
      end
      if group_by[:type] == :flat
        return {count: {terms: {field: group_by[:name]}}}
      end
    end

    def self.convert_ranges_to_elastic_search(ranges)
      ranges.map do |range|
        {from: range[0], to: range[1]}
      end
    end

    def self.classify_group_by_field(field_name)
      field_name = field_name.first if field_name.is_a? Array and field_name.size == 1

      if field_name.is_a? Array
        {type: :range, name: field_name[0], ranges: field_name[1]}
      else
        date_captures = field_name.match /\A(year|month|week|day)\(([^\)]+)\)\Z/
        if date_captures
          {type: :date, name: date_captures[2], interval: date_captures[1]}
        else
          find_in_searchable_fields(field_name)
        end
      end
    end

    def self.find_in_searchable_fields(name)
      find_in_fields name, Event.searchable_fields
    end

    def self.find_in_fields(name, fields=[])
      sub_field_found = nil
      found = fields.detect do |field|
        field[:name].to_s == name.to_s || (field[:type] == :nested && (sub_field_found = find_in_fields(name, field[:sub_fields])))
      end
      if found
        if found[:type] == :nested
          {type: :nested, name: found[:name], sub_fields: sub_field_found}
        else
          {type: :flat, name: found[:name]}
        end
      end
    end

    def self.process_group_by_buckets(aggregations, group_by, events, event, doc_count)
      count = aggregations[:count]
      if count
        if group_by.is_an? Array
          head = group_by.first
          rest = group_by[1..-1]
        else
          head = group_by
          rest = []
        end
        case head[:type]
        when :range
          process_bucket(rest, events, event, count[:buckets]) do |bucket|
            {head[:name] => [normalize(bucket[:from]), normalize(bucket[:to])]}
          end
        when :date
          process_bucket(rest, events, event, count[:buckets]) do |bucket|
            {head[:name] => bucket[:key_as_string]}
          end
        when :flat
          process_bucket(rest, events, event, count[:buckets]) do |bucket|
            {head[:name] => bucket[:key]}
          end
        when :nested
          process_group_by_buckets(count, head[:sub_fields], events, event, doc_count)
        else
          raise "Trying to group by a non searchable field"
        end
      else
        event[:count] = doc_count
        events + [event]
      end
    end

    def self.process_bucket(group_by, events, event, buckets)
      buckets.inject events do |events, bucket|
        event = event.merge(yield bucket)
        process_group_by_buckets(bucket, group_by, events, event, bucket[:doc_count])
      end
    end

    def self.normalize(value)
      if value.is_a? Float
        truncated_value = trunc(value)
        if truncated_value == value
          return truncated_value
        end
      end
      value
    end
  end
end
