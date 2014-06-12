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
  io:format("mapping: ~p~n", [Mapping]),
  TargetField = proplists:get_value(target_field, Mapping),
  Selector = proplists:get_value(selector, Mapping),
  Type = proplists:get_value(type, Mapping),
  Pii = proplists:get_value(pii, Mapping),

  Value = apply_selector(Selector, Data),
  check_valid_value(Value, TargetField, proplists:get_value(valid_values, Mapping)),
  Value2 = apply_value_mappings(Value, TargetField, proplists:get_value(value_mappings, Mapping)),

  Key = hash_key(Type, TargetField, proplists:get_value(indexed, Mapping), Pii),
  Element = proplists:get_value(Key, Event),
  Element2 = [{TargetField, Value} | Element],
  Event2 = proplists:delete(Key, Event),
  [{Key, Element2} | Event2].

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
    false ->
      erlang:error(
        mapping_error,
        io_lib:format("'~s' is not a valid value for '~s' (valid options are: ~s)", [Value, TargetField, string:join(Options, ", ")]));
    _ -> ok
  end.

check_value_in_range(Value, TargetField, Range) ->
  Min = proplists:get_value(min, Range),
  Max = proplists:get_value(max, Range),

  if
    not ((Min =< Value) and (Value =< Max)) ->
      erlang:error(
        mapping_error,
        io_lib:format("'~s' is not a valid value for '~s' (valid values must be between ~s and ~s)", [Value, TargetField, Min, Max]))
  end.

check_value_is_date(Value, TargetField, DateFormat) ->
  case DateFormat of
    iso ->
      case tempo:parse(iso8601, {datetime, Value}) of
        {error, _} ->
          erlang:error(
            mapping_error,
            io_lib:format("'~s' is not a valid value for '~s' (valid value must be an iso date)", [Value, TargetField]));
        {ok, _} ->
          ok
      end
  end.

apply_value_mappings(Value, _, undefined) ->
  Value;

apply_value_mappings(Value, TargetField, Mappings) ->
    MappingsKeys = dict:keys(Mappings),
    Star = re:compile("\\*"),
    MatchedMapping = list_utils:find(fun(Mapping) ->
      re:replace(Mapping, Star, ".*", [{return, list}]),
      case re:match(Mapping, Value) of
        {match, _Captured} -> true;
        nomatch -> false
      end
    end,
    undefined,
    MappingsKeys),

    case MatchedMapping of
      undefined ->
        erlang:error(
          mapping_error,
          io_lib:format("'~s' is not a valid value for '~s' (valid value must be in one of these forms: ~s)", [Value, TargetField, string:join(MappingsKeys, ", ")]));
      _ -> proplists:get_value(MatchedMapping, Mappings)
    end.
