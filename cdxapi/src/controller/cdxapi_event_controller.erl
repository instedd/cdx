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
% jsx:decode(<<"{\"library\": \"jsx\", \"awesome\": true}">>).
% jsx:encode([{<<"library">>,<<"jsx">>},{<<"awesome">>,true}]).
  io:format("req: ~p~n", [Req]),
  {json, [{events, "Hello world!"}]}.
  % EventId = Req:post_param("id"),
  % NewEvent = event:new(id, EventId),
  % case NewEvent:save() of
  %   {ok, SavedEvent} ->
  %     {redirect, [{action, "list"}]};
  %   {error, ErrorList} ->
  %     {ok, [{errors, ErrorList}, {new_msg, NewEvent}]}
  % end.

goodbye('POST', []) ->
  boss_db:delete(Req:post_param("event_id")),
  {redirect, [{action, "list"}]}.


% #### to convert a utf8 binary containing a json string into an erlang term ####

% ```erlang
% 1> jsx:decode(<<"{\"library\": \"jsx\", \"awesome\": true}">>).
% [{<<"library">>,<<"jsx">>},{<<"awesome">>,true}]
% 2> jsx:decode(<<"[\"a\",\"list\",\"of\",\"words\"]">>).
% [<<"a">>, <<"list">>, <<"of">>, <<"words">>]
% ```

% #### to convert an erlang term into a utf8 binary containing a json string ####

% ```erlang
% 1> jsx:encode([{<<"library">>,<<"jsx">>},{<<"awesome">>,true}]).
% <<"{\"library\": \"jsx\", \"awesome\": true}">>
% 2> jsx:encode(#{<<"library">> => <<"jsx">>, <<"awesome">> => true}).
% <<"{\"awesome\":true,\"library\":\"jsx\"}">>
% 3> jsx:encode([<<"a">>, <<"list">>, <<"of">>, <<"words">>]).
% <<"[\"a\",\"list\",\"of\",\"words\"]">>
% ```
