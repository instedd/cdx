defmodule Elasticsearch do
  require Lager

  def default_url do
    'http://localhost:9200'
  end

  def initialize do
    :inets.start
    {status, result} = :httpc.request(:put, {index_template_url, [], '', template_as_json}, [], [])
    case result do
      {{_, 200, _ },_, _ } -> status
      {{_, error_code, _ },_, _ }   ->
        log_error(result)
        error_code
      _ ->
        log_error(result)
        status
    end
  end

  defp log_error(result) do
    Lager.error("ES test results indices mapping definition failed: #{inspect(result)}")
  end

  def index_template_url do
    :string.join([default_url, '_template', 'test_results_index_template'], '/')
  end

  defp template_as_json do
    JSEX.encode!([template: "#{index_prefix}*", mappings: [ test_result: [ properties: build_properties_mapping]]])
  end

  defp build_properties_mapping do
    Enum.map TestResult.serchable_fields, fn {name, type, _} ->
      map_field(name, type)
    end
  end

  defp map_field(field, type) do
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
