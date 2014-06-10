-module(foo_test).

-export([start/0]).

start() ->
  boss_web_test:get_request("/event/foo", [],
    [fun boss_assert:http_ok/1], []).
