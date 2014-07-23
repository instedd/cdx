module Cdx::Api::Elasticsearch::EventGrouping
  class << self
    def query_with_group_by(query, group_by)
      group_by =
        case group_by
        when String, Symbol
          group_by.to_s.split ","
        when Hash
          [group_by]
        else
          Array(group_by)
        end

      group_by = group_by.map do |field|
        classify_group_by_field field
      end

      nested_fields = group_by.select {|f| f[:type] == "nested"}
      non_nested_fields = group_by.reject {|f| f[:type] == "nested"}

      aggregations = Cdx::Api::Elasticsearch::Aggregations.new
      aggregations.append non_nested_fields if non_nested_fields.present?
      aggregations.append nested_fields if nested_fields.present?

      event = Cdx::Api.search_elastic aggregations.to_hash.merge(query: query)
      process_group_by_buckets(event["aggregations"].with_indifferent_access, (non_nested_fields + nested_fields), [], {}, 0)
    end

    def classify_group_by_field(field_name)
      field_name = field_name.first if field_name.is_a? Array and field_name.size == 1

      if field_name.is_a? Hash
        name = field_name.keys.first
        value = field_name[name]
      else
        name = field_name
        value = nil
      end
      classified_field = nil
      Cdx::Api.searchable_fields.detect do |field|
        classified_field = field.grouping_detail_for name, value
      end
      classified_field
    end

    def process_group_by_buckets(aggregations, group_by, events, event, doc_count)
      count = aggregations[:count] || aggregations[:kind]
      if count
        if group_by.is_a? Array
          head = group_by.first
          rest = group_by[1..-1]
        else
          head = group_by
          rest = []
        end
        case head[:type]
        when "range"
          process_bucket(rest, events, event, count[:buckets]) do |bucket|
            {head[:name] => [normalize(bucket[:from]), normalize(bucket[:to])]}
          end
        when "date"
          process_bucket(rest, events, event, count[:buckets]) do |bucket|
            {head[:field][:name] => bucket[:key_as_string]}
          end
        when "flat"
          process_bucket(rest, events, event, count[:buckets]) do |bucket|
            {head[:name] => bucket[:key]}
          end
        when "kind"
          elements = head[:elements]
          buckets = count[:buckets].select do |bucket|
            elements.include? bucket[:key]
          end
          process_bucket(rest, events, event, buckets) do |bucket|
            {head[:reference_table][:name].singularize => bucket[:key]}
          end
        when "nested"
          process_bucket(rest, events, event, (count[:count] || count)[:buckets]) do |bucket|
            {head[:sub_fields][:name] => bucket[:key]}
          end
        else
          raise "Trying to group by a non searchable field"
        end
      else
        event[:count] = doc_count
        events + [event]
      end
    end

    def process_bucket(group_by, events, event, buckets)
      buckets.inject events do |events, bucket|
        event = event.merge(yield bucket)
        process_group_by_buckets(bucket, group_by, events, event, bucket[:doc_count])
      end
    end

    def normalize(value)
      return value.round if value.is_a? Float and value.round == value
      value
    end
  end
end
