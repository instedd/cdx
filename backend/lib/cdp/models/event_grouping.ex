defmodule EventGrouping do
  def query_with_group_by(query, group_by) do
    if is_list(group_by) do
      all_group_by = group_by

      # Handle the case when they send us:
      #
      #     ["field", ranges]
      #
      # instead of:
      #
      #     [["field", ranges]]
      case group_by do
        [name, range] when is_binary(name) and is_list(range) ->
          all_group_by = [all_group_by]
        _ -> :ok
      end
    else
      all_group_by = String.split(group_by, ",")
    end

    all_group_by = sort_group_by(all_group_by)

    aggregations = process_group_by(all_group_by)

    query = [
      search: [
        query: query,
        aggregations: aggregations,
        size: 0
      ],
      index: "#{Elasticsearch.index_prefix}*"
    ]

    event = Tirexs.Query.create_resource(query)

    process_group_by_buckets(event.aggregations, all_group_by, [], [], 0)
  end

  # nested fields must appear last in the group by
  defp sort_group_by(fields) do
    group_nested_fields Enum.sort fields, fn(f1, f2) ->
      g1 = classify_group_by_field(f1)
      g2 = classify_group_by_field(f2)

      case g1 do
        {:nested, _, _} ->
          case g2 do
            {:nested, _, _} ->
              f1 < f2
            _ ->
              false
          end
        _ ->
          case g2 do
            {:nested, _, _} ->
              true
            _ ->
              f1 < f2
          end
      end
    end
  end

  defp group_nested_fields([]) do
    []
  end

  defp group_nested_fields([field | fields]) do
    group_nested_fields(classify_group_by_field(field), fields)
  end

  defp group_nested_fields({:nested, _nesting_field, {:flat, field_name}}, fields) do
    [{:nested, [{:nested, _nesting_field, {:flat, field_name}}] ++ find_all_in_searchable_fields(fields)}]
  end

  defp group_nested_fields(field, fields) do
    [field] ++ group_nested_fields(fields)
  end

  defp process_group_by_buckets(aggregations, all_group_by, events, event, doc_count) do
    count = aggregations[:count]
    if count do
      [first_group_by | other_group_by] = all_group_by

      case first_group_by do
        {:range, field, _ranges} ->
          process_bucket(other_group_by, events, event, count[:buckets], fn(bucket) -> {field, [normalize(bucket[:from]), normalize(bucket[:to])]} end)
        {:date, _interval, field} ->
          process_bucket(other_group_by, events, event, count[:buckets], fn(bucket) -> {field, bucket[:key_as_string]} end)
        {:flat, field_name} ->
          process_bucket(other_group_by, events, event, count[:buckets], fn(bucket) -> {field_name, bucket[:key]} end)
        {:nested, fields} ->
          process_group_by_buckets(count, fields, events, event, doc_count)
        {:nested, _nesting_field, {:flat, field_name}} ->
          process_bucket(other_group_by, events, event, count[:buckets], fn(bucket) -> {field_name, bucket[:key]} end)
        nil ->
          raise "Trying to group by a non searchable field"
      end
    else
      event = event ++ [count: doc_count]
      [event | events]
    end
  end

  defp process_bucket(other_group_by, events, event, buckets, mapping) do
    Enum.reduce buckets, events, fn(bucket, events) ->
      event = event ++ [mapping.(bucket)]
      process_group_by_buckets(bucket, other_group_by, events, event, bucket[:doc_count])
    end
  end

  def date_regex do
    ~r/\A(year|month|week|day)\(([^\)]+)\)\Z/
  end

  def match_date_regex(string) do
    captures = Regex.run(date_regex, string)
    if captures do
      [_, interval, field] = captures
      {interval, field}
    else
      nil
    end
  end

  defp classify_group_by_field([field_name]) do
    classify_group_by_field(field_name)
  end

  defp classify_group_by_field(field_name) do
    if is_list(field_name) do
      [name, ranges] = field_name
      {:range, name, ranges}
    else
      date_captures = match_date_regex(field_name)
      if date_captures do
        {interval, field} = date_captures
        {:date, interval, field}
      else
        find_in_searchable_fields(field_name)
      end
    end
  end

  defp find_all_in_searchable_fields([name |rest]) do
    [find_in_searchable_fields(name) | find_all_in_searchable_fields(rest)]
  end

  defp find_all_in_searchable_fields([]) do
    []
  end

  defp find_in_searchable_fields(name) do
    find_in_fields name, Event.searchable_fields
  end

  defp find_in_fields(_name, []) do
    nil
  end

  defp find_in_fields(name, [{field_name, :nested, properties} | fields]) do
    found = find_in_fields(name, properties)
    if found do
      {:nested, field_name, found}
    else
      find_in_fields(name, fields)
    end
  end

  defp find_in_fields(name, [{field_name, _, _} | fields]) do
    if name == atom_to_binary(field_name) do
      {:flat, name}
    else
      find_in_fields(name, fields)
    end
  end

  defp process_group_by([]) do
    []
  end

  defp process_group_by([{:nested, [nested_field | rest]}]) do
    case nested_field do
      {:nested, nesting_field, {:flat, field_name}} ->
        [
          count: [
            nested: [path: nesting_field],
            aggs: [
              count: [
                terms: [field: "#{nesting_field}.#{field_name}"]
              ] ++ process_group_by(rest)
            ]
          ]
        ]
      _ ->
        raise "Trying to group by a non searchable field"
    end
  end

  defp process_group_by([group_by]) do
    case group_by do
      {:range, name, ranges} ->
        [count: [range: [field: name, ranges: convert_ranges_to_elastic_search(ranges)]]]
      {:date, interval, field} ->
        format = case interval do
                         "year"  -> "yyyy"
                         "month" -> "yyyy-MM"
                         "week"  -> "yyyy-'W'w"
                         "day"   -> "yyyy-MM-dd"
                       end
        [count: [date_histogram: [field: field, interval: interval, format: format]]]
      {:flat, field_name} ->
        [count: [terms: [field: field_name]]]
      {:nested, nesting_field, {:flat, field_name}} ->
        [
          aggs: [
            count: [
              terms: [field: "#{nesting_field}.#{field_name}"]
            ]
          ]
        ]
      _ ->
        raise "Trying to group by a non searchable field"
    end
  end

  defp process_group_by([group_by|rest]) do
    rest_aggregations = process_group_by(rest)
    group_by_aggregations = process_group_by([group_by])

    [
      count: (group_by_aggregations[:count] ++ [aggregations: rest_aggregations])
    ]
  end

  defp convert_ranges_to_elastic_search([]) do
    []
  end

  defp convert_ranges_to_elastic_search([[from, to] | other]) do
    [[from: from, to: to] | convert_ranges_to_elastic_search(other)]
  end

  defp normalize(value) when is_float(value) do
    truncated_value = trunc(value)
    if truncated_value == value do
      truncated_value
    else
      value
    end
  end

  defp normalize(value) do
    value
  end
end
