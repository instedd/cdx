defmodule Cdp.Elasticsearch do
  # use Lager

  def default_url do
    "http://localhost:9200"
  end

  def initialize do
    url = index_template_url()
    template_json_binary = iolist_to_binary(template_as_json())
    {status, result} = :httpc.request(:put, {Url, [], "", template_json_binary}, [], [])
    case status do
      :ok -> status
      _   -> "ES test results indices mapping definition failed"
      # _   -> :lager.warning("ES test results indices mapping definition failed: ~p", [result]), status
    end
  end

def index_template_url do
  :string.join([default_url(), "_template", "test_results_index_template"], "/")
end

defp template_as_json do
  properties = build_properties_mapping()
  JSON.encode({:struct, [
    {:template, 'cdp_institution_*'},
    {:mappings, {:struct, [
      {:test_result, {:struct, [
        {:properties, {:struct, properties}}
      ]}}
    ]}}
  ]})
end

defp build_properties_mapping do
  Enum.map Cdp.TestResult.serchable_fields, fn {name, type} ->
    map_field(name, type)
  end
end

defp map_field(field, type) do
  fieldBody = case type do
    :multi_field ->
         {:fields,
            {:struct, [
              {:analyzed, {:struct, [{type, :string}, {:index, :analyzed}]}},
              {"@#{field}", {:struct, [{type, :string}, {:index, :not_analyzed}]}}
            ]}};
    _ -> {:index, :not_analyzed}
  end
  {"@#{field}", {:struct, [{type, type}, fieldBody]}}
end

defp template do
  '{
        "template" : "cdp_*",
        "settings" : {
          "index.refresh_interval" : "5s",
          "analysis" : {
            "analyzer" : {
              "default" : {
                "type" : "standard",
                "stopwords" : "_none_"
              }
            }
          }
        },
        "mappings" : {
          "_default_" : {
             "_all" : {"enabled" : true},
             "dynamic_templates" : [ {
               "string_fields" : {
                 "path_match" : "@fields.*",
                 "match_mapping_type" : "string",
                 "mapping" : {
                   "type" : "multi_field",
                     "fields" : {
                       "{name}" : {"type": "string", "index" : "analyzed", "omit_norms" : true },
                       "raw" : {"type": "string", "index" : "not_analyzed", "ignore_above" : 256}
                     }
                 }
               }
             } ],
             "properties" : {
               "@version": { "type": "string", "index": "not_analyzed" },
               "@timestamp" : { "type": "date", "index": "not_analyzed" },
               "@tags" : { "type": "string", "index": "not_analyzed" },
               "@activity" : { "type": "string", "index": "not_analyzed" },
               "@parent" : { "type": "string", "index": "not_analyzed" },
               "@source" : {
                 "type": "multi_field",
                 "fields": {
                  "analyzed": { "type": "string", "index": "analyzed" },
                  "@source": { "type": "string", "index": "not_analyzed" }
                 }
               }
             }
          }
        }
      }'
  end
end
