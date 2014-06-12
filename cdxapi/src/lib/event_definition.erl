-module(event_definition).
-compile(export_all).

sensitive_fields() ->
  [
    patient_id,
    patient_name,
    patient_telephone_number,
    patient_zip_code
  ].

searchable_fields() ->
  [
    {created_at, date, [
      {"since", {range, [from, {include_lower, true}]}},
      {"until", {range, [to, {include_lower, true}]}}
    ]},
    {event_id, integer, [{"event_id", match}]},
    {device_uuid, string, [{"device", match}]},
    {laboratory_id, integer, [{"laboratory", match}]},
    {institution_id, integer, [{"institution", match}]},
    {location_id, integer, []},
    {parent_locations, integer, [{"location", match}]},
    {age, integer, [
      {"age", match},
      {"min_age", {range, [from, {include_lower, true}]}},
      {"max_age", {range, [to, {include_upper, true}]}}
    ]},
    {assay_name, string, [{"assay_name", wildcard}]},
    {device_serial_number, string, []},
    {gender, string, [{"gender", wildcard}]},
    {uuid, string, [{"uuid", match}]},
    {start_time, date, []},
    {system_user, string, []},
    {results, nested, [
      {result, multi_field, [{"result", wildcard}]},
      {condition, string, [{"condition", wildcard}]}
    ]}
  ].

pii(Field) ->
  lists:member(Field, sensitive_fields()).
  % list:member(erlang:binary_to_atom(Field), sensitive_fields()).
