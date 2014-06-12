-module(manifest_test).
-include_lib("eunit/include/eunit.hrl").

apply_to_indexed_core_field_test() ->
  assert_manifest_application([[
      {target_field, assay_name},
      {selector, "assay/name"},
      {type, core}
    ]],
    [{"assay", [{"name", "GX4002"}]}],
    [{indexed , [{assay_name, "GX4002"}]}, {pii, []}, {custom, []}]).

apply_to_pii_core_field_test() ->
  assert_manifest_application([[
      {target_field, patient_name},
      {selector, "patient/name"},
      {type, core}
    ]],
    [{"patient", [{"name", "John"}]}],
    [{pii, [{patient_name, "John"}]}, {indexed, []}, {custom, []}]).

assert_manifest_application(Mappings, Data, Expected) ->
  Manifest = manifest:new(id, created_at, updated_at, 1, [{field_mapping, Mappings}]),

  Result = Manifest:apply_to(Data),
  io:format("result: ~p~n", [Result]),
  io:format("expected: ~p~n", [Expected]),
  ?assertEqual(Result, Expected).

% defp assert_manifest_application(mappings_json, data, expected) do
%   manifest_json = """
%     {
%       "field_mapping" : #{mappings_json}
%     }
%     """
%   manifest = JSEX.decode!(manifest_json)
%   result = Manifest.apply(manifest, data)
%   assert result == expected
% end

% all_test_() ->
%   [fun should_update_index/0].

% should_update_index() ->
%   meck:new(httpc),
%   try
%     Attrs1 = [{foo, "foo value"}],
%     Attrs2 = [{bar, "bar value"}],
%     List = [{1, 2010, Attrs1}, {2, 2012, Attrs2}],
%     Header1 = build_header(1, 2010),
%     Header2 = build_header(2, 2012),
%     Doc1 = build_doc(Attrs1),
%     Doc2 = build_doc(Attrs2),
%     Expected = <<Header1/binary, "\n", Doc1/binary, "\n", Header2/binary, "\n", Doc2/binary, "\n">>,
%     meck:expect(httpc, request, fun(put, {Url, [], "", BatchRequest}, [], []) ->
%       ?assertEqual(elastic_search:bulk_url(), Url),
%       ?assertEqual(Expected, BatchRequest),
%       {ok, {{"HTTP/1.1", 200, "OK"}, [], []}}
%     end),
%     ?assertMatch({ok, _}, elastic_search:batch_update(List)),
%     ?assert(meck:validate(httpc))
%   after
%     meck:unload(httpc)
%   end.

% build_header(Id, Year) ->
%   iolist_to_binary(mochijson2:encode({struct, [
%     {update, {struct, [
%       {'_index', list_to_binary(["test_results_", integer_to_list(Year)])},
%       {'_type', test_result},
%       {'_id', Id}
%     ]}}
%   ]})).

% build_doc(Attributes) ->
%   iolist_to_binary(mochijson2:encode({struct, [{doc, {struct, Attributes}}]})).


% should_build_errors_with_custom_description_for_failed_self_test() ->
%   DatagramRecord = sample_datagram_record([{type, kdg_failed_self_test},
%                                            {error_code, 6},
%                                            {params, [1,2,3,4]}]),

%   Error = datagram:build_error(sample_test_result(), DatagramRecord),
%   ?assertEqual(<<"FailedSelfTest : 4006 Syringe motor doesn't work (1;2;3;4)">>, Error#test_result_error.description).
