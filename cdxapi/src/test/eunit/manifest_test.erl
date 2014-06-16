-module(manifest_test).
-include_lib("eunit/include/eunit.hrl").

apply_to_indexed_core_field_test() ->
  assert_manifest_application([[
      {target_field, assay_name},
      {selector, "assay/name"},
      {type, core}
    ]],
    [{"assay", [{"name", "GX4002"}]}],
    [{indexed, [{assay_name, "GX4002"}]}, {pii, []}, {custom, []}]).

apply_to_pii_core_field_test() ->
  assert_manifest_application([[
      {target_field, patient_name},
      {selector, "patient/name"},
      {type, core}
    ]],
    [{"patient", [{"name", "John"}]}],
    [{indexed, []}, {pii, [{patient_name, "John"}]}, {custom, []}]).

apply_to_custom_non_pii_non_indexed_field_test() ->
  assert_manifest_application([[
      {target_field, temperature},
      {selector, "temperature"},
      {type, custom},
      {pii, false},
      {indexed, false}
    ]],
    [{"temperature", 20}],
    [{indexed, []}, {pii, []}, {custom, [{temperature, 20}]}]).

apply_to_custom_non_pii_indexed_field_test() ->
  assert_manifest_application([[
      {target_field, temperature},
      {selector, "temperature"},
      {type, custom},
      {pii, false},
      {indexed, true}
    ]],
    [{"temperature", 20}],
    [{indexed, [{temperature, 20}]}, {pii, []}, {custom, []}]).

apply_to_custom_pii_field_test() ->
  assert_manifest_application([[
      {target_field, temperature},
      {selector, "temperature"},
      {type, custom},
      {pii, true},
      {indexed, false}
    ]],
    [{"temperature", 20}],
    [{indexed, []}, {pii, [{temperature, 20}]}, {custom, []}]).

doesnt_raise_on_valid_value_in_options_test() ->
  assert_manifest_application([[
      {target_field, level},
      {selector, "level"},
      {type, custom},
      {pii, false},
      {indexed, true},
      {valid_values, [
        {options, ["low", "medium", "high"]}
      ]}
    ]],
    [{"level", "high"}],
    [{indexed, [{level, "high"}]}, {pii, []}, {custom, []}]).

raises_on_invalid_value_in_options_test() ->
    assert_raises_manifest_data_validation([[
          {target_field, level},
          {selector, "level"},
          {type, custom},
          {pii, false},
          {indexed, true},
          {valid_values, [
            {options, ["low", "medium", "high"]}
          ]}
        ]],
      [{"level", "John Doe"}]).

doesnt_raise_on_valid_value_in_range_test() ->
    assert_manifest_application([[
          {target_field, temperature},
          {selector, "temperature"},
          {type, custom},
          {pii, false},
          {indexed, true},
          {valid_values, [
            {range, [
              {min, 30},
              {max, 30}
            ]}
          ]}
        ]],
      [{"temperature", 30}],
      [{indexed, [{temperature, 30}]}, {pii, []}, {custom, []}]).

raise_on_invalid_value_in_range_lesser_test() ->
    assert_raises_manifest_data_validation([[
          {target_field, temperature},
          {selector, "temperature"},
          {type, custom},
          {pii, false},
          {indexed, true},
          {valid_values, [
            {range, [
              {min, 30},
              {max, 31}
            ]}
          ]}
        ]],
      [{"temperature", 29.9}]).

raise_on_invalid_value_in_range_greater_test() ->
    assert_raises_manifest_data_validation([[
          {target_field, temperature},
          {selector, "temperature"},
          {type, custom},
          {pii, false},
          {indexed, true},
          {valid_values, [
            {range, [
              {min, 30},
              {max, 31}
            ]}
          ]}
        ]],
      [{"temperature", 31.1}]).

doesnt_raise_on_valid_value_in_date_iso_test() ->
    assert_manifest_application([[
          {target_field, sample_date},
          {selector, "sample_date"},
          {type, custom},
          {pii, false},
          {indexed, true},
          {valid_values, [
            {date, "iso"}
          ]}
        ]],
      [{"sample_date", "2014-05-14T15:22:11+0000"}],
      [{indexed, [{sample_date, "2014-05-14T15:22:11+0000"}]}, {pii, []}, {custom, []}]).

raise_on_invalid_value_in_date_iso_test() ->
    assert_raises_manifest_data_validation([[
          {target_field, sample_date},
          {selector, "sample_date"},
          {type, custom},
          {pii, false},
          {indexed, true},
          {valid_values, [
            {date, "iso"}
          ]}
        ]],
      [{"sample_date", "John Doe"}]).

applies_first_value_mapping_test() ->
    assert_manifest_application([[
          {target_field, condition},
          {selector, "condition"},
          {type, custom},
          {pii, false},
          {indexed, true},
          {value_mappings, [
            {"*MTB*", "MTB"},
            {"*FLU*", "H1N1"},
            {"*FLUA*", "A1N1"}
          ]}
        ]],
      [{"condition", "PATIENT HAS MTB CONDITION"}],
      [{indexed, [{condition, "MTB"}]}, {pii, []}, {custom, []}]).

applies_second_value_mapping_test() ->
    assert_manifest_application([[
          {target_field, condition},
          {selector, "condition"},
          {type, custom},
          {pii, false},
          {indexed, true},
          {value_mappings, [
            {"*MTB*", "MTB"},
            {"*FLU*", "H1N1"},
            {"*FLUA*", "A1N1"}
          ]}
        ]],
      [{"condition", "PATIENT HAS FLU CONDITION"}],
      [{indexed, [{condition, "H1N1"}]}, {pii, []}, {custom, []}]).

raise_on_mapping_not_found_test() ->
    assert_raises_manifest_data_validation([[
          {target_field, condition},
          {selector, "condition"},
          {type, custom},
          {pii, false},
          {indexed, true},
          {value_mappings, [
            {"*MTB*", "MTB"},
            {"*FLU*", "H1N1"},
            {"*FLUA*", "A1N1"}
          ]}
        ]],
      [{"condition", "PATIENT IS OK"}]).

assert_manifest_application(Mappings, Data, Expected) ->
  Manifest = manifest:new(id, created_at, updated_at, 1, [{field_mapping, Mappings}]),

  Result = Manifest:apply_to(Data),
  io:format("result: ~p~n", [Result]),
  io:format("expected: ~p~n", [Expected]),
  ?assertEqual(Result, Expected).

assert_raises_manifest_data_validation(Mappings, Data) ->
  Manifest = manifest:new(id, created_at, updated_at, 1, [{field_mapping, Mappings}]),

  ?assertThrow(mapping_error, Manifest:apply_to(Data)).
