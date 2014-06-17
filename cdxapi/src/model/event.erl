-module(event, [Id, DeviceId, CreatedAt, UpdatedAt, Uuid, EventId, CustomFields, RawData, SensitiveData]).
-compile(export_all).

before_create() ->
  Now = calendar:now_to_universal_time(erlang:now()),
  {ok, set([{created_at, Now}, {updated_at, Now}])}.

before_update() ->
  {ok, set(updated_at, calendar:now_to_universal_time(erlang:now()))}.

validation_tests() ->
  [
    % DeviceId Required
    {fun() ->
      DeviceId =/= undefined andalso
        Uuid =/= 0
    end, {device_id, "Required"}},
    % Uuid Required
    {fun() ->
      Uuid =/= undefined andalso
        length(Uuid) =/= 0
    end, {uuid, "Required"}},
    % EventId Required
    {fun() ->
      EventId =/= undefined andalso
        EventId =/= 0
    end, {event_id, "Required"}},
    % CustomFields Required
    {fun() ->
      CustomFields =/= undefined andalso
        length(CustomFields) =/= 0
    end, {custom_fields, "Required"}},
    % RawData Required
    {fun() ->
      RawData =/= undefined andalso
        length(RawData) =/= 0
    end, {raw_data, "Required"}},
    % SensitiveData Required
    {fun() ->
      SensitiveData =/= undefined andalso
        length(SensitiveData) =/= 0
    end, {sensitive_data, "Required"}}
 ].
