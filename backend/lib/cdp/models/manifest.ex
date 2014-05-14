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

    case type do
      "core" ->
        if TestResult.pii?(target_field) do
          key = :pii
        else
          key = :indexed
        end
      "custom" ->
        key = :custom
    end

    value = apply_selector(selector, data)
    element = result[key]
    element = Dict.put(element, target_field, value)
    Dict.put(result, key, element)
  end

  defp apply_selector(selector, data) do
    # Keep it simple for now: split by '/' and index on that
    paths = String.split selector, "/"
    Enum.reduce paths, data, fn(path, current) ->
      current[path]
    end
  end
end
