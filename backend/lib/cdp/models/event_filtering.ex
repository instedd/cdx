defmodule EventFiltering do

  def query(params, post_body) do
    conditions = process_conditions(params, [])
    conditions = process_conditions(post_body, conditions)

    query = and_conditions(conditions)
    order = process_order(params)

    group_by = params["group_by"] || post_body["group_by"]

    if group_by do
      events = EventGrouping.query_with_group_by(query, group_by)
    else
      events = query_without_group_by(query, order)
    end

    Enum.map events, fn event -> Enum.into(event, %{}) end
  end

  defp query_without_group_by(query, sort) do
    query = [
      search: [
        query: query,
        sort: sort,
      ],
      index: "#{Elasticsearch.index_prefix}*"
    ]
    event = Tirexs.Query.create_resource(query)
    Enum.map event.hits, fn(hit) -> hit[:_source] end
  end

  def field_matcher(field_name, :multi_field) do
    "#{field_name}.analyzed"
  end

  def field_matcher(field_name, _) do
    field_name
  end

  defp process_fields(fields, params, conditions) do
    Enum.reduce fields, conditions, fn field, conditions ->
      process_field(field, params, conditions)
    end
  end

  defp process_field({field_name, type, [{param_name, :wildcard}| tail ]}, params, conditions) do
    if field_value = params[param_name] do
      condition = if Regex.match? ~r/.*\*.*/, field_value do
        [wildcard: [{field_name, field_value}]]
      else
        [match: [{field_matcher(field_name, type), field_value}]]
      end
      conditions = [condition | conditions]
    end
    process_field({field_name, type, tail}, params, conditions)
  end

  defp process_field({field_name, type, [{param_name, :match}| tail ]}, params, conditions) do
    if field_value = params[param_name] do
      condition = [match: [{field_name, field_value}]]
      conditions = [condition | conditions]
    end
    process_field({field_name, type, tail}, params, conditions)
  end

  defp process_field({field_name, type, [{param_name, {:range, [start | options]}}| tail ]}, params, conditions) do
    if field_value = params[param_name] do
      condition = [range: [{field_name, [{start, field_value}] ++ options}]]
      conditions = [condition | conditions]
    end
    process_field({field_name, type, tail}, params, conditions)
  end

  defp process_field({field_name, :nested, nested_fields}, params, conditions) do
    nested_fields = Enum.map nested_fields, fn({name, type, properties}) ->
      {"#{field_name}.#{name}", type, properties}
    end
    nested_conditions = process_fields(nested_fields, params, [])
    case nested_conditions do
      [] ->
        conditions
      _  ->
        condition = [
          nested: [
            path: field_name,
            query: and_conditions(nested_conditions),
          ]
        ]
        [condition | conditions]
    end
  end

  defp process_field({_, _, []}, _, conditions) do
    conditions
  end

  defp process_conditions(params, conditions) do
    conditions = process_fields(Event.searchable_fields, params, conditions)

    if Enum.empty?(conditions) do
      condition = [match_all: []]
      conditions = [condition | conditions]
    end

    conditions
  end

  defp and_conditions([condition]) do
    condition
  end

  defp and_conditions(conditions) do
    [bool: [must: conditions]]
  end

  defp process_order(params) do
    if order = params["order_by"] do
      all_orders = String.split(order, ",")
      Enum.map all_orders, fn(order) ->
        if String.starts_with?(order, "-") do
          {String.slice(order, 1, String.length(order) - 1), "desc"}
        else
          {order, "asc"}
        end
      end
    else
      [[created_at: "asc"]]
    end
  end
end
