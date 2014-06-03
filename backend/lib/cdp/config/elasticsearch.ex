defmodule Elasticsearch do
  require Lager

  def default_url do
    'http://localhost:9200'
  end

  def initialize do
    :inets.start
    {status, event} = :httpc.request(:put, {index_template_url, [], '', template_as_json}, [], [])
    case event do
      {{_, 200, _ },_, _ } -> status
      {{_, error_code, _ },_, _ }   ->
        log_error(event)
        error_code
      _ ->
        log_error(event)
        status
    end
  end

  defp log_error(event) do
    Lager.error("ES event indices mapping definition failed: #{inspect(event)}")
  end

  def index_template_url do
    :string.join([default_url, '_template', 'events_index_template'], '/')
  end

  defp template_as_json do
    JSEX.encode!([template: "#{index_prefix}*", mappings: [ event: [ properties: build_properties_mapping]]])
  end

  defp build_properties_mapping do
    map_fields Event.searchable_fields
  end

  defp map_fields(fields) do
    Enum.map fields, fn {name, type, properties} ->
      map_field(name, type, properties)
    end
  end

  defp map_field(field, :nested, nested_fields) do
    {field, [type: :nested, properties: map_fields(nested_fields)]}
  end

  defp map_field(field, type, _properties) do
    field_body = case type do
      :multi_field ->
            [
              fields: [
                {:analyzed, [{:type, :string}, {:index, :analyzed}]},
                {field, [{:type, :string}, {:index, :not_analyzed}]}
              ]
            ]
      _ -> [index: :not_analyzed]
    end
    {field, [type: type] ++ field_body}
  end

  def index_prefix do
    "cdp_institution_#{Mix.env}"
  end
end
