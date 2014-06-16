-module(manifest, [Id, CreatedAt, UpdatedAt, Version, Definition]).
-compile(export_all).
-table("manifests").

  % Manifest:definition(),
  % Definition
  % [{indexed , [{assay_name, "GX4002"}]}, {pii, []}, {custom, []}].

apply_to(Data) ->
  Event = [
      {indexed, []},
      {pii, []},
      {custom, []}
    ],

  lists:foldl(
    fun(Mapping, Event) ->
      apply_single_mapping(Mapping, Data, Event)
    end,
    Event,
    proplists:get_value(field_mapping, Definition)).

apply_single_mapping(Mapping, Data, Event) ->
  TargetField = proplists:get_value(target_field, Mapping),
  Selector = proplists:get_value(selector, Mapping),
  Type = proplists:get_value(type, Mapping),
  Pii = proplists:get_value(pii, Mapping),

  Value = apply_selector(Selector, Data),
  check_valid_value(Value, TargetField, proplists:get_value(valid_values, Mapping)),
  MappedValue = apply_value_mappings(Value, TargetField, proplists:get_value(value_mappings, Mapping)),

  Key = hash_key(Type, TargetField, proplists:get_value(indexed, Mapping), Pii),
  Element = [{TargetField, MappedValue} | proplists:get_value(Key, Event)],
  lists:keystore(Key, 1, Event, {Key, Element}).

hash_key(core, TargetField, _Indexed, _Pii) ->
  case event_definition:pii(TargetField) of
    true -> pii;
    false -> indexed
  end;

hash_key(custom, _TargetField, _Indexed, true) ->
  pii;

hash_key(custom, _TargetField, true, false) ->
  indexed;

hash_key(custom, _TargetField, false, false) ->
  custom.

apply_selector(Selector, Data) ->
  % Keep it simple for now: split by '/' and index on that
  Paths = string:tokens(Selector, "/"),
  lists:foldl(
    fun(Path, Current) ->
      proplists:get_value(Path, Current)
    end,
    Data,
    Paths).

check_valid_value(Value, _TargetField, undefined) ->
  Value;

check_valid_value(Value, TargetField, ValidValues) ->
  case proplists:get_value(options, ValidValues) of
    undefined -> ok;
    Options -> check_value_in_options(Value, TargetField, Options)
  end,
  case proplists:get_value(range, ValidValues) of
    undefined -> ok;
    Range -> check_value_in_range(Value, TargetField, Range)
  end,
  case proplists:get_value(date, ValidValues) of
    undefined -> ok;
    Date -> check_value_is_date(Value, TargetField, Date)
  end.

check_value_in_options(Value, TargetField, Options) ->
  case lists:member(Value, Options) of
    false -> throw(mapping_error);
        % io_lib:format("'~s' is not a valid value for '~s' (valid options are: ~s)", [Value, TargetField, string:join(Options, ", ")]));
    _ -> ok
  end.

check_value_in_range(Value, TargetField, Range) ->
  Min = proplists:get_value(min, Range),
  Max = proplists:get_value(max, Range),

  case ((Min =< Value) and (Value =< Max)) of
    false -> throw(mapping_error);
        % io_lib:format("'~s' is not a valid value for '~s' (valid values must be between ~s and ~s)", [Value, TargetField, Min, Max]))
    _ -> ok
  end.

check_value_is_date(Value, TargetField, DateFormat) ->
  case DateFormat of
    "iso" ->
      try
        tempo:parse(iso8601, {datetime, iolist_to_binary(Value)})
      catch
        Exception:Reason -> throw(mapping_error)
      end
  end.

apply_value_mappings(Value, _, undefined) ->
  Value;

apply_value_mappings(Value, TargetField, Mappings) ->
    MappingKeys = proplists:get_keys(Mappings),
    MatchedMapping = find_mappign(fun(Mapping) ->
      RegexMapping = re:replace(Mapping, "\\*", ".*", [{return, list}, global]),
      re:run(Value, RegexMapping)
    end,
    undefined,
    MappingKeys),
    case MatchedMapping of
      undefined ->
        throw(mapping_error);
          % io_lib:format("'~s' is not a valid value for '~s' (valid value must be in one of these forms: ~s)", [Value, TargetField, string:join(MappingKeys, ", ")]));
      _ -> proplists:get_value(MatchedMapping, Mappings)
    end.

find_mappign(Condition, Default, [E | Rest]) ->
  case Condition(E) of
    {match, _Captured} -> E;
    nomatch -> find_mappign(Condition, Default, Rest)
  end;

find_mappign(_Cond, Default, []) -> Default.

