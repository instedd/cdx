-module(cdxapi_event_controller, [Req]).
-compile(export_all).

hello('GET', []) ->
  {ok, [{events, "Hello, world!"}]}.

foo('GET', []) ->
  {output, "Hello, Foo!"}.

bar('GET', []) ->
  {json, [{events, "Hello, world!"}]}.

list('GET', []) ->
  Events = boss_db:find(event, []),
  {ok, [{events, Events}]}.

create('GET', []) ->
  ok;
create('POST', []) ->
  EventId = Req:post_param("id"),
  NewEvent = event:new(id, EventId),
  case NewEvent:save() of
    {ok, SavedEvent} ->
      {redirect, [{action, "list"}]};
    {error, ErrorList} ->
      {ok, [{errors, ErrorList}, {new_msg, NewEvent}]}
  end.

goodbye('POST', []) ->
  boss_db:delete(Req:post_param("event_id")),
  {redirect, [{action, "list"}]}.
