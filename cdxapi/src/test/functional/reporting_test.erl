-module(reporting_test).
-export([start/0]).

start() ->
  boss_web_test:post_request("/event/create", [], [jsx:encode([{<<"event">>,<<"positive">>}])],
    [fun boss_assert:http_ok/1,
      fun(Res) ->
        io:format("response: ~p~n", [Res]),
        [Event] = boss_db:find(event, []),
        {false, implement_properly}
      end], []).
