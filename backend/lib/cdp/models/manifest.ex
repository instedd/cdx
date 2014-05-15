defmodule Manifest do
  def apply(manifest, data) do
    result = %{
      indexed: %{},
      pii: %{},
      custom: %{},
    }

    Enum.reduce manifest["field_mapping"], result, fn(mapping, result) ->
      apply_single_mapping(mapping, data, result)
    end
  end

  defp apply_single_mapping(mapping, data, result) do
    target_field = mapping["target_field"]
    selector = mapping["selector"]
    type = mapping["type"]

    value = apply_selector(selector, data)
    check_valid_value(value, target_field, mapping["valid_values"])

    key = hash_key(type, target_field, mapping)
    element = result[key]
    element = Dict.put(element, target_field, value)
    Dict.put(result, key, element)
  end

  defp hash_key(type, target_field, mapping) do
    case type do
      "core" ->
        if TestResult.pii?(target_field) do
          :pii
        else
          :indexed
        end
      "custom" ->
        indexed = mapping["indexed"]
        if indexed do
          :indexed
        else
          :custom
        end
    end
  end

  defp apply_selector(selector, data) do
    # Keep it simple for now: split by '/' and index on that
    paths = String.split selector, "/"
    Enum.reduce paths, data, fn(path, current) ->
      current[path]
    end
  end

  defp check_valid_value(value, target_field, nil) do
    value
  end

  defp check_valid_value(value, target_field, valid_values) do
    if options = valid_values["options"]do
      check_value_in_options(value, target_field, options)
    end

    if range = valid_values["range"] do
      check_value_in_range(value, target_field, range)
    end

    if date = valid_values["date"] do
      check_value_is_date(value, target_field, date)
    end
  end

  defp check_value_in_options(value, target_field, options) do
    unless Enum.member? options, value do
      raise "'#{value}' is not a valid value for '#{target_field}' (valid options are: #{Enum.join options, ", "})"
    end
  end

  defp check_value_in_range(value, target_field, range) do
    min = range["min"]
    max = range["max"]

    unless min <= value and value <= max do
      raise "'#{value}' is not a valid value for '#{target_field}' (valid values must be between #{min} and #{max})"
    end
  end

  defp check_value_is_date(value, target_field, date_format) do
    case date_format do
      "iso" ->
        case :tempo.parse(:iso8601, {:datetime, value}) do
          {:error, _} ->
            raise "'#{value}' is not a valid value for '#{target_field}' (valid value must be an iso date)"
          {:ok, _} ->
            :ok
        end
    end
  end
end
